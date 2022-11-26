function install::filesync() {
    # scoped to specific workspace
    if is::cde; then {
        log::info "Performing local filesync, scoped to ${HOSTNAME:-"${GITPOD_WORKSPACE_ID:-}"} workspace";
        if test -e "$workspace_persist_dir"; then {
          TARGET="$workspace_persist_dir" filesync::restore_local;
        } else {
          TARGET="$workspace_persist_dir" filesync::save_local "${files_to_persist_locally[@]}";
        } fi
    } fi
    
    filesync::mount_rclone;
}

function filesync::mount_rclone {
    # scoped globally, where ever you can use `rclone`.
    # some of these variables are defined at /src/variables.sh
    declare -n rclone_data="$rclone_gitpod_env_var_name";
    if test -n "${rclone_data:-}"; then {
        
        # Create rclone config from $RCLONE_DATA
        mkdir -p "${rclone_conf_file%/*}";
        printf '%s\n' "${rclone_data}" | base64 -d > "$rclone_conf_file";

        # Wait for rclone to be fully installed
        await::until_true command::exists rclone;

        log::info "Performing cloud filesync, scoped globally";

        # Mount your cloud provider at $rclone_mount_dir
        mkdir -p "${rclone_mount_dir}";
        sudo "$(command -v rclone)" "${rclone_cmd_args[@]}";
        # declare times=0;
        # until test -e "$rclone_dotfiles_sh_dir"; do {
        #     sleep 1;
        #     if test $times -gt 10; then {
        #         break;
        #     } fi
        #     ((times=times+1));
        # } done
        until mountpoint -q "$rclone_mount_dir"; do sleep 1; done;

        # Relative home dotfiles
        if test -e "$rclone_dotfiles_sh_sync_relative_home_dir"; then {
            #  WHERE-TO          FUNCTION                         SOURCE
            # Install dotfiles from the cloud provider
            TARGET="$HOME" dotfiles::initialize "$rclone_dotfiles_sh_sync_relative_home_dir";
        } fi

        # Full rootfs absolute sync
        if test -e "$rclone_dotfiles_sh_sync_rootfs_dir"; then {
          TARGET="$rclone_dotfiles_sh_sync_rootfs_dir" filesync::restore_local;
        } fi

    } fi
}

function filesync::restore_local {
    declare +x TARGET;
    declare target_persist_dir="${TARGET}";
    mkdir -p "$target_persist_dir";
    declare _input _destination_node _destination_node_dir;

    while read -r _input; do {
        _destination_node="${_input#"${target_persist_dir}"}"
        _destination_node="${_destination_node//\/\//\/}";
        _destination_node_dir="${_destination_node%/*}";

        if test -L "$_destination_node" || test -e "$_destination_node"; then {
            log::info "Overwriting ${_destination_node} with workspace persisted file";
            try_sudo rm -f "$_destination_node";
        } fi
        try_sudo mkdir -p "${_destination_node%/*}";
        try_sudo ln -sf "$_input" "$_destination_node";
    } done < <(find "$target_persist_dir" -type f)
}

function filesync::save_local() {
    declare +x TARGET;
    declare target_persist_dir="${TARGET}";
    mkdir -p "$target_persist_dir";
    declare _input _input_dir _persisted_node _persisted_node_dir;

    for _input in "$@"; do {
        if test ! -v RELATIVE_HOME; then {
          _persisted_node="${target_persist_dir}/${_input}";
        } else {
          if ! [[ "$_input" == $HOME/* ]]; then {
            log::error "$_input is not inside your \$HOME directory" 1 || return;
          } fi
          _persisted_node="${target_persist_dir}/${_input#"$HOME"}";
        } fi
        _persisted_node="${_persisted_node//\/\//\/}";
        _persisted_node_dir="${_persisted_node%/*}";
        _input_dir="${_input%/*}";

        if test "$_input_dir" == "$_input"; then { 
          log::error "Something went wrong, _input_dir is same as _input" 1 || return;
        } fi

        if test ! -e "$_persisted_node"; then {
            try_sudo mkdir -p "$_persisted_node_dir";

            if test ! -e "$_input" && test ! -d "$_input"; then {
                try_sudo sh -c "mkdir -p \"$_input_dir\" && printf '' > \"$_input\"";
            } fi

            try_sudo cp -ra "$_input" "$_persisted_node_dir";
            try_sudo rm -rf "$_input";
            try_sudo ln -sf "$_persisted_node" "$_input";
        } else {
            log::warn "$_input is already persisted";
        } fi
    } done
}

function filesync::cli() {

  function cli::save() {

    case "${1:-}" in
      -h|--help)
        printf '%s\t%s\n' \
          "$___self filesync save [options] [PATH ...]" "" \
          "" "" \
          "OPTIONS:" "" \
          "-dh|--dynamic-home" "Save in dynamic home" \
          "-h|--help" "This help message";
        exit;
        ;;
      -dh|--dynamic-home)
        declare arg_rel_home=true;
        shift;
        ;;
    esac

    declare file filelist;

    for file in "$@"; do {
      log::info "Saving $file";
      filelist+=("$(realpath -s "$file")") || true;
    } done
    
    if test ! -v arg_rel_home; then {
      TARGET="$rclone_dotfiles_sh_sync_rootfs_dir" filesync::save_local "${filelist[@]}";
    } else {
      TARGET="$rclone_dotfiles_sh_sync_relative_home_dir" RELATIVE_HOME="true" filesync::save_local "${filelist[@]}";
    } fi
  }

  function cli::remove() {
    declare input persisted_node;
    for input in "$@"; do {
      if persisted_node="$(realpath -e "$input" 2>/dev/null)" && [[ "$persisted_node" == "$rclone_dotfiles_sh_sync_dir"* ]]; then {
        log::info "Removing $persisted_node";
        try_sudo rm -r "$input" "$persisted_node";
        unset persisted_node;
      } else {
        log::error "$input wasn't saved" 1 || exit;
      } fi
    } done
  }

    case "${1:-}" in
      -h|--help)
        printf '%s\t%s\n' \
          "save" "Start syncing selected files" \
          "remove" "Remove file from sync" \
          "restore" "Manual file sync trigger" \
          "-h|--help" "This help message";
        ;;
      save|restore|remove)
        if ! mountpoint -q "$rclone_mount_dir"; then {
          log::error "rclone is not configured, run ${BGREEN}dotsh config rclone${RC} first." 1 || exit;
        } fi
        declare cmd="$1";
        shift;
        cli::"$cmd" "$@";
        ;;
    esac

    exit;
}
