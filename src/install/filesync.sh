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

    # scoped globally, where ever you can use `rclone`.
    # some of these variables are defined at /src/variables.sh
    if test -n "${RCLONE_DATA:-}"; then {
        
        # Create rclone config from $RCLONE_DATA
        mkdir -p "${rclone_conf_file%/*}";
        printf '%s\n' "${RCLONE_DATA}" | base64 -d > "$rclone_conf_file";

        # Wait for rclone to be fully installed
        await::until_true command::exists rclone;

        log::info "Performing cloud filesync, scoped globally";
        # Mount your cloud provider at $rclone_mount_dir

        mkdir -p "${rclone_mount_dir}";
        sudo "$(command -v rclone)" "${rclone_cmd_args[@]}" & disown;

        # Install dotfiles from the cloud provider
        declare rclone_dotfiles_sh_dir="$rclone_mount_dir/.dotfiles-sh";
        declare rclone_dotfiles_sh_sync_dir="$rclone_dotfiles_sh_dir/sync";
        declare rclone_dotfiles_sh_sync_relative_home_dir="$rclone_dotfiles_sh_sync_dir/relhome";
        declare rclone_dotfiles_sh_sync_rootfs_dir="$rclone_dotfiles_sh_sync_dir/rootfs";

        declare times=0;
        until test -e "$rclone_dotfiles_sh_dir"; do {
            sleep 1;
            if test $times -gt 10; then {
                break;
            } fi
            ((times=times+1));
        } done

        # Relative home dotfiles
        if test -e "$rclone_dotfiles_sh_sync_relative_home_dir"; then {
            #  WHERE-TO          FUNCTION                         SOURCE
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
    declare _input _persisted_node _persisted_node_dir;

    while read -r _input; do {
        _persisted_node="${_input#"${target_persist_dir}"}"
        _persisted_node_dir="${_persisted_node%/*}";

        if test -e "$_persisted_node"; then {
            log::info "Overwriting ${_input} with workspace persisted file";
            try_sudo mkdir -p "${_input%/*}";
            try_sudo ln -sf "$_persisted_node" "$_input";
        } fi
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
          _persisted_node_dir="${_persisted_node%/*}";
          _input_dir="${_input%/*}";
        } else {
          _persisted_node="${target_persist_dir}/${_input#"$HOME"}";
          _persisted_node_dir="${_persisted_node%/*}";
          _input_dir="${_input%/*}";
        } fi

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
            try_sudo ln -sr "$_persisted_node" "$_input";
        } else {
            log::warn "$_input is already persisted";
        } fi
    } done
}

function filesync::cli() {

  function cli::save {

    case "${1:-}" in
      -h|--help)
        printf '%s\t%s\n' \
          "-rh" "Save in global home" \
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
      filelist+=("$(readlink "$file")") || true;
    } done
    
    if test ! -v arg_rel_home; then {
      filesync::save_local "${filelist[@]}";
    } else {
      RELATIVE_HOME="$arg_rel_home" filesync::save_local "${filelist[@]}";
    } fi
  }

    case "${1:-}" in
      "filesync")
        shift;
      ;;
      *) 
        return;
      ;;
    esac
      

    case "${1:-}" in
      -h|--help)
        printf '%s\t%s\n' \
          "save" "Start syncing selected files" \
          "restore" "Manual file sync trigger" \
          "-h|--help" "This help message";
        ;;
      save)
        shift;
        cli::save "$@";
        ;;
      restore)
        shift;
        cli::restore "$@";
        ;;
    esac

    exit;
}
