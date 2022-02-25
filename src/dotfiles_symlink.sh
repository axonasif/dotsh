function dotfiles_symlink() {
    local _dotfiles_repo="${1:-"$___self_REPOSITORY"}";
    local _dotfiles_dir="${2:-$HOME/.dotfiles}";
    local _target_file _target_dir;
    local _git_output;
    
    if test ! -e "$_dotfiles_dir"; then {
        _git_output="$(
            git -c credential.helper="/usr/bin/gp credential-helper" \
                -c user.name="$GITPOD_GIT_USER_NAME" \
                -c user.email="$GITPOD_GIT_USER_EMAIL" \
            clone "$_dotfiles_repo" "$_dotfiles_dir" 2>&1
        )" 2>/dev/null || log::error "$_git_output" && return 0;
    } fi
    
    if test -e "$_dotfiles_dir" ; then {

        # Process .dotfiles ignore
        local _dotfiles_ignore="$_dotfiles_dir/.dotfilesignore";
        local _thing_path;
        local _ignore_list=(
            -not -path "'*/.git/*'"
            -not -path "'*/.dotfilesignore'"
            -not -path "'*/.gitpod.yml'"
        );

        if test -e "$_dotfiles_ignore"; then {
            while read _ignore_thing; do {
                if [[ ! "$_ignore_thing" =~ ^\# ]]; then {
                    _ignore_list+=(-not -path "'$_ignore_thing'");
                } fi
                # _thing_path="$(readlink -f "$_dotfiles_dir/$_ignore_thing")";
                # if test -f "$_thing_path"; then {
                #     _ignore_list+=("-not -path '$_thing_path'");
                # } elif test -d "$_thing_path"; then {
                #     _ignore_list+=("-not -path '/$_thing_path/*'");
                # } fi
            } done < "$_dotfiles_ignore"
        } fi

        pushd "$_dotfiles_dir" 1>/dev/null;
        while read -r _file ; do {
            _target_file="$HOME/${_file##${_dotfiles_dir}/}";
            _target_dir="${_target_file%/*}";
            if test ! -d "$_target_dir"; then {
                mkdir -p "$_target_dir";
            } fi
            ln -srf "$_file" "$_target_file";
            unset _target_file _target_dir;
        }  done < <(printf '%s\n' "${_ignore_list[@]}" | xargs find . -type f);
        popd 1>/dev/null;
    } fi
}