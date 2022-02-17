#!/usr/bin/bash -eu

function main() {

    # if test ! -e /ide/bin/gitpod-code || test ! -v GITPOD_REPO_ROOT; then {
        # printf 'error: This script is meant to be run on Gitpod, quiting...\n' && exit 1;

    ## When running inside Gitpod
    if test -e /ide/bin/gitpod-code && test -v GITPOD_REPO_ROOT; then {

        local _source_dir="$(readlink -f "$0")" && _source_dir="${_source_dir%/*}";
        local _private_dir="$_source_dir/.private";

        # Fetch private stuff
        local _target_file _target_dir _private_files;
        git clone https://github.com/axonasif/dotfiles.private "$_private_dir" && {
            mapfile -t _private_files < <(find "$_private_dir");
            for _file in "${_private_files[@]}"; do {
                _target_file="$HOME/${_file###${_private_dir}/}";
                _target_dir="${_target_file%/*}";
                if test ! -d "$_target_dir"; then {
                    mkdir -p "$_target_dir";
                } fi
                ln -srf "$_file" "$_target_file";
                unset _target_file _target_dir;
            }  done
        }

        # Install bashbox
        curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall;

        # TODO: Add shell history syncer

        # TODO: Add gpg signing
    } fi

}

main "$@";
wait && exit;