use std::print::log;

function main() {

    # if test ! -e /ide/bin/gitpod-code || test ! -v GITPOD_REPO_ROOT; then {
        # printf 'error: This script is meant to be run on Gitpod, quiting...\n' && exit 1;

    ## When running inside Gitpod
    if test -e /ide/bin/gitpod-code && test -v GITPOD_REPO_ROOT; then {

        log::info "Gitpod environment detected!";
        local _source_dir="$(readlink -f "$0")" && _source_dir="${_source_dir%/*}";
        local _workspace_persist_dir="/workspace/.persist";
        local _private_dir="$_source_dir/.private";
        local _shell_hist_files=(
            "$HOME/.bash_history"
            "$HOME/.local/share/fish/fish_history"
        )

        # Fetch private stuff
        log::info "Installing private dotfiles";
        local _target_file _target_dir _private_files;
        git clone https://github.com/axonasif/dotfiles.private "$_private_dir" && {
            while read -r _file ; do {
                _target_file="$HOME/${_file##${_private_dir}/}";
                _target_dir="${_target_file%/*}";
                if test ! -d "$_target_dir"; then {
                    mkdir -p "$_target_dir";
                } fi
                ln -srf "$_file" "$_target_file";
                unset _target_file _target_dir;
            }  done < <(find "$_private_dir" -type f -not -path '*/\.git/*');
        }

        # Install bashbox
        curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall;

        # TODO: Add shell history syncer over git

        # Use workspace persisted history
        log::info "Persiting shell histories to /workspace";
        local _hist;
        for _hist in "${_shell_hist_files[@]}"; do {
            _hist_name="${_hist##*/}";
            if test -e "$_workspace_persist_dir/$_hist_name"; then {
                log::warn "Overwriting $_hist with workspace persisted history file";
                ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist";
            } else {
                cp "$_hist" "$_workspace_persist_dir/";
                ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist";
            } fi
            unset _hist_name;
        } done
        

        # TODO: Add gpg signing
    } fi

}