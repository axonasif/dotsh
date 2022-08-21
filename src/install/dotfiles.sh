function install::dotfiles() {
    local _dotfiles_repo="${1}";
    local _dotfiles_dir="${2}";
    local _target_file _target_dir;
    local _git_output;
    
    if test ! -e "$_dotfiles_dir"; then {
        git clone --filter=tree:0 "$_dotfiles_repo" "$_dotfiles_dir" > /dev/null 2>&1 || :;
    } fi
    
    if test -e "$_dotfiles_dir" ; then {

        # Process .dotfiles ignore
        local _dotfiles_ignore="$_dotfiles_dir/.dotfilesignore";
        local _thing_path;
        local _ignore_list=(
            -not -path "'*/.git/*'"
            -not -path "'*/.dotfilesignore'"
            # -not -path "'*/.gitpod.yml'"
            -not -path "'$_dotfiles_dir/src/*'"
            -not -path "'$_dotfiles_dir/target/*'"
            -not -path "'$_dotfiles_dir/Bashbox.meta'"
            -not -path "'$_dotfiles_dir/install.sh'"
        );

        if test -e "$_dotfiles_ignore"; then {
            while read -r _ignore_thing; do {
                if [[ ! "$_ignore_thing" =~ ^\# ]]; then {
                    _ignore_thing="$_dotfiles_dir/${_ignore_thing}";
                    _ignore_thing="${_ignore_thing//\/\//\/}";
                    _ignore_list+=(-not -path "$_ignore_thing");
                } fi
                unset _ignore_thing;
                # _thing_path="$(readlink -f "$_dotfiles_dir/$_ignore_thing")";
                # if test -f "$_thing_path"; then {
                #     _ignore_list+=("-not -path '$_thing_path'");
                # } elif test -d "$_thing_path"; then {
                #     _ignore_list+=("-not -path '/$_thing_path/*'");
                # } fi
            } done < "$_dotfiles_ignore"
        } fi

        # pushd "$_dotfiles_dir" 1>/dev/null;
        while read -r _file ; do {
            _target_file="$HOME/${_file#${_dotfiles_dir}/}";
            _target_dir="${_target_file%/*}";
            if test ! -d "$_target_dir"; then {
                mkdir -p "$_target_dir";
            } fi
            # echo "s: $_file"
            # echo "t: $_target_file"
            ln -sf "$_file" "$_target_file";
            unset _target_file _target_dir;
        }  done < <(printf '%s\n' "${_ignore_list[@]}" | xargs find "$_dotfiles_dir" -type f);
        # popd 1>/dev/null;
    } fi
}
