function install::dotfiles() {
    function symlink_files() {
        local _dotfiles_repo="${1}";
        local _dotfiles_dir="${2}";
	local _installation_target="${3:-"$HOME"}"
	local last_applied_filelist="$source_dir/.git/.last_applied";
        
        if test ! -e "$_dotfiles_dir"; then {
            git clone --filter=tree:0 "$_dotfiles_repo" "$_dotfiles_dir" > /dev/null 2>&1 || :;
        } fi

	# Clean out any broken symlinks
	if test -e "$last_applied_filelist"; then {
		while read -r file; do {
			if test ! -e "$file"; then {
				log::info "Cleaning up broken dotfiles link: $file";
				rm -f "$file" || :;
			} fi
		} done < "$last_applied_filelist"
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

	    # Reset last_applied_filelist
	    printf '' > "$last_applied_filelist";
        	local _target_file _target_dir;
            while read -r _file ; do {
                _target_file="$_installation_target/${_file#${_dotfiles_dir}/}";
                _target_dir="${_target_file%/*}";
                if test ! -d "$_target_dir"; then {
                    mkdir -p "$_target_dir";
                } fi
                # echo "s: $_file"
                # echo "t: $_target_file"
                ln -sf "$_file" "$_target_file";
		printf '%s\n' "$_target_file" >> "$last_applied_filelist";
                unset _target_file _target_dir;
            }  done < <(printf '%s\n' "${_ignore_list[@]}" | xargs find "$_dotfiles_dir" -type f);
            # popd 1>/dev/null;
        } fi
    }

    local _private_dir="$source_dir/.private"; # Path to private dotfiles directory
    # You can set PRIVATE_DOTFILES_REPO with */* scope in https://gitpod.io/variables for your personal dotfiles
    local _private_dotfiles_repo="${PRIVATE_DOTFILES_REPO:-}"; # This is a git URL

    # Local dotfiles from this repository
    log::info "Installing local dotfiles";
    symlink_files "$___self_REPOSITORY" "$source_dir/raw";

    # Private dotfiles
    if test -n "$_private_dotfiles_repo"; then {
        log::info "Installing private dotfiles";
        symlink_files "${PRIVATE_DOTFILES_REPO:-"$_private_dotfiles_repo"}" "$_private_dir" || :;
    } fi
}
