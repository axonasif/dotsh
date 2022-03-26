use std::print::log;
use dotfiles_symlink;
use utils;
use install;

function main() {

    if is::gitpod; then {
        log::info "Gitpod environment detected!";
        local _workspace_persist_dir="/workspace/.persist";
        local _shell_hist_files=(
            "$HOME/.bash_history"
            "$HOME/.zsh_history"
            "$HOME/.local/share/fish/fish_history"
        )
    } fi
    local _source_dir="$(readlink -f "$0")" && _source_dir="${_source_dir%/*}";
    local _private_dir="$_source_dir/.private";
    local _private_dotfiles_repo="https://github.com/axonasif/dotfiles.private";

    # Start installation of system(apt) packages in the background
    log::info "Installing system packages in the background";
    install::system_packages;

    # Install local dotfiles
    log::info "Installing local dotfiles";
    dotfiles_symlink;

    # Install private dotfiles
    # Note: you can set PRIVATE_DOTFILES_REPO with */* scope in https://gitpod.io/variables for your personal dotfiles
    log::info "Will install private dotfiles after the VSCODE IDE starts";
    (gp await-port 23000 1>/dev/null && dotfiles_symlink "${PRIVATE_DOTFILES_REPO:-"$_private_dotfiles_repo"}" "$_private_dir" || :) &

    # Install tools
    log::info "Installing userland tools in the background";
    install::userland_tools;

    if is::gitpod; then {
        # Use workspace persisted history
        log::info "Persiting Gitpod shell histories to /workspace";
        mkdir -p "$_workspace_persist_dir";
        local _hist;
        for _hist in "${_shell_hist_files[@]}"; do {
            mkdir -p "${_hist%/*}";
            _hist_name="${_hist##*/}";
            if test -e "$_workspace_persist_dir/$_hist_name"; then {
                log::warn "Overwriting $_hist with workspace persisted history file";
                ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist";
            } else {
                touch "$_hist";
                cp "$_hist" "$_workspace_persist_dir/";
                ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist";
            } fi
            unset _hist_name;
        } done
        
        # Make gitpod task spawned terminals use fish
        log::info "Setting fish as the interactive shell for Gitpod task terminals"
        if ! grep 'PROMPT_COMMAND=".*exec fish"' $HOME/.bashrc 1>/dev/null; then {
            # The supervisor creates the task terminals, supervisor calls BASH from `/bin/bash` instead of the realpath `/usr/bin/bash`
            printf '%s\n' 'PROMPT_COMMAND="[ "$BASH" == /bin/bash ] && [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ] && test -v bash_ran && exec fish || bash_ran=true;$PROMPT_COMMAND"' >> $HOME/.bashrc;
        } fi
        # Append .gitpod.yml:tasks hist to fish_hist
        log::info "Appending .gitpod.yml:tasks shell histories to fish_history";
        while read -r _command; do {
            if test -n "$_command"; then {
                printf '\055 cmd: %s\n  when: %s\n' "$_command" "$(date +%s)" >> "${_shell_hist_files[2]}";
            } fi 
        } done < <(sed "s/\r//g" /workspace/.gitpod/cmd-*)
    } fi

    if test -n "$(jobs -p)"; then {
        log::warn "Waiting for background jobs to complete";
    } fi

    # TODO: Add gpg signing
    # TODO(Not sure if this makes sense): Add shell history syncer over git (specific to Gitpod, not necessary locally)

}