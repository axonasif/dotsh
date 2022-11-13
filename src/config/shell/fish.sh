function config::shell::fish() {

    # Lock binary
    await::create_shim_nix_common_wrapper "fish";

    # Install fisher plugin manager
    log::info "Installing fisher and some plugins for fish-shell";

    mkdir -p "$fish_confd_dir";
    {
        fish -c "curl -sL https://git.io/fisher | source && fisher install ${fish_plugins[*]}";

        # Fisher plugins
        # fish -c 'fisher install lilyball/nix-env.fish'; # Might not be necessary because of my own .config/fish/conf.d/bash_env.fish
    } >/dev/null 2>&1

    CLOSE=true await::create_shim "$exec_path";
}

function config::shell::fish::append_hist_from_gitpod_tasks() {
    await::signal get install_dotfiles;
    # Append .gitpod.yml:tasks hist to fish_hist
    log::info "Appending .gitpod.yml:tasks shell histories to fish_history";
    mkdir -p "${fish_hist_file%/*}";
    while read -r _command; do {
        if test -n "$_command"; then {
            printf '\055 cmd: %s\n  when: %s\n' "$_command" "$(date +%s)" >> "$fish_hist_file";
        } fi 
    } done < <(sed "s/\r//g" /workspace/.gitpod/cmd-* 2>/dev/null || :)
}