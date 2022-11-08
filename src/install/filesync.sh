function install::filesync() {
    # scoped to specific workspace
    if is::cde; then {
        log::info "Performing local filesync, scoped to ${HOSTNAME:-"${GITPOD_WORKSPACE_ID:-}"} workspace";
        local files_to_persist_locally=(
            "${HISTFILE:-"$HOME/.bash_history"}"
            "${HISTFILE:-"$HOME/.zsh_history"}"
            "$fish_hist_file"
        )
        if test -e "$workspace_persist_dir"; then {
            filesync::restore_local;
        } else {
            filesync::save_local "${files_to_persist_locally[@]}";
        } fi
    } fi

    # scoped globally, where ever you can use `rclone`.
    # some of these variables are defined at /src/variables.sh
    if test -n "${RCLONE_DATA:-}"; then {
        
        # Create rclone config from $RCLONE_DATA
        mkdir -p "${rclone_conf_file%/*}";
        printf '%s\n' "${RCLONE_DATA}" | base64 -d > "$rclone_conf_file";

        # Wait for rclone to be fully installed
        await::until_true command -v rclone 1>/dev/null;

        log::info "Performing cloud filesync, scoped globally";
        # Mount your cloud provider at $rclone_mount_dir
        declare rclone_cmd_args=(
            --config="$rclone_conf_file"
            mount
            --allow-other
            --async-read
            --vfs-cache-mode=full
            "${rclone_profile_name}:" "$rclone_mount_dir"
        )
        mkdir -p "${rclone_mount_dir}";
        sudo "$(command -v rclone)" "${rclone_cmd_args[@]}" & disown;

        # Install dotfiles from the cloud provider
        local rclone_dotfiles_dir="$rclone_mount_dir/dotfiles";
        local times=0;
        until test -e "$rclone_dotfiles_dir"; do {
            sleep 1;
            if test $times -gt 10; then {
                break;
            } fi
            ((times=times+1));
        } done
        if test -e "$rclone_dotfiles_dir"; then {
            #  WHERE-TO          FUNCTION              SOURCE
            TARGET="$HOME" dotfiles::initialize "$rclone_dotfiles_dir";
        } fi

    } fi
}

function filesync::restore_local {
    mkdir -p "$workspace_persist_dir";
    local _input _persisted_node _persisted_node_dir;

    while read -r _input; do {
        _persisted_node="${_input#"${workspace_persist_dir}"}"
        _persisted_node_dir="${_persisted_node%/*}";

        if test -e "$_persisted_node"; then {
            log::info "Overwriting ${_input} with workspace persisted file";
            try_sudo mkdir -p "${_input%/*}";
            ln -sf "$_persisted_node" "$_input";
        } fi
    } done < <(find "$workspace_persist_dir" -type f)
}

function filesync::save_local() {
    mkdir -p "$workspace_persist_dir";
    local _input _input_dir _persisted_node _persisted_node_dir;

    for _input in "$@"; do {
        _persisted_node="${workspace_persist_dir}/${_input}";
        _persisted_node_dir="${_persisted_node%/*}";
        _input_dir="${_input%/*}";

        if test ! -e "$_persisted_node"; then {
            mkdir -p "$_persisted_node_dir" "$_input_dir";
            if test ! -d "$_input"; then {
                printf '' > "$_input";
            } fi
            cp -ra "$_input" "$_persisted_node_dir";
            
            rm -rf "$_input";
            ln -sr "$_persisted_node" "$_input";
        } else {
            log::warn "$_input is already persisted";
        } fi
    } done
}