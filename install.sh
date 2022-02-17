#!/usr/bin/bash -eu

if test ! -e /ide/bin/gitpod-code || test ! -v GITPOD_REPO_ROOT; then {
    printf 'error: This script is meant to be run on Gitpod, quiting...\n' && exit 1;
} fi

_source_dir="$(readlink -f "$0")" && _source_dir="${_source_dir%/*}";
_private_dir="$_source_dir/.private";

# Fetch private stuff
git clone https://github.com/axonasif/dotfiles.private "$_private_dir" && {
    mapfile -t _private_files < <(find "$_private_dir");
    for _file in "${_private_files[@]}"; do {
        _target_file="$HOME/${_file###${_private_dir}/}";
        _target_dir="${_target_file%/*}";
        if test ! -d "$_target_dir"; then {
            mkdir -p "$_target_dir";
        } fi
        ln -srf "$_file" "$_target_file";
    }  done
}

printf "Just testing\n"