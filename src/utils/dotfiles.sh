function dotfiles::initialize() {
	await::until_true command::exists git;
	
	local installation_target="${INSTALL_TARGET:-"$HOME"}";
	local last_applied_filelist="$installation_target/.last_applied_dotfiles";
	local	\
      dotfiles_repo \
			local_dotfiles_repo_count \
			repo_user \
			repo_name \
			source_dir \
			repo_dir_name \
			check_dir;
	mkdir -p "$dotfiles_sh_repos_dir";

	# Clean out any broken symlinks
	if test -e "$last_applied_filelist"; then {
		while read -r file; do {
			if test ! -e "$file"; then {
				log::info "Cleaning up broken dotfiles link: $file";
				rm -f "$file" || :;
			} fi
		} done < "$last_applied_filelist"

		# Reset last_applied_filelist
		printf '' > "$last_applied_filelist";
	} fi

	for dotfiles_repo in "$@"; do {

		if ! [[ "$dotfiles_repo" =~ (https?|git):// ]]; then {
			# Local dotfiles repo
			: "$dotfiles_repo";
		} else {
			# Remote dotfiles repo

			repo_user="${dotfiles_repo%/*}" && repo_user="${repo_user##*/}";
			repo_name="${dotfiles_repo##*/}";
			repo_dir_name="--${repo_user}_${repo_name}";

			check_dir=("$dotfiles_sh_repos_dir"/*"$repo_dir_name");
			if test -n "${check_dir:-}"; then {
				: "${check_dir[0]}";
			} else {
				local_dotfiles_repo_count=("$dotfiles_sh_repos_dir"/*);
				local_dotfiles_repo_count="${#local_dotfiles_repo_count[*]}";
				: "${dotfiles_sh_repos_dir}/$(( local_dotfiles_repo_count + 1 ))${repo_dir_name}";
			} fi
		} fi

		local source_dir="${SOURCE_DIR:-"$_"}";
		
		if test ! -e "${source_dir}"; then {
			rm -rf "$source_dir";
			git clone --filter=tree:0 "$dotfiles_repo" "$source_dir" > /dev/null 2>&1 || :;
		} fi

		if test -e "$source_dir" ; then {
      declare -a roots=("/");
      declare -a ignore;

      # Process .dotfiles config
      declare dotfiles_config_file="$source_dir/.dotfiles";
      if test -e "$dotfiles_config_file"; then {
        source "$dotfiles_config_file";
      } fi

      declare root;
      for root in "${roots[@]}"; do {

        declare root_dir="$source_dir/$root";
        root_dir="${root_dir//\/\//\/}" && root_dir="${root_dir%/}";
        log::info "Installing ${source_dir##*/}";

        # Detect custom dotfiles managers
        ## chezmoi
        if test -n "$(find "$root_dir" -mindepth 1 -maxdepth 1 -type f \( -name '*chezmoi*' -o -name '*.tmpl' \))"; then {
          dotfiles::use_chezmoi "$root_dir";
          continue;
        } fi

        # Process .dotfilesignore
        local _ignore_list=(
          -not -path '*/.git/*'
          -not -path '*/.dotfilesignore'
          -not -path '*/.gitpod*'
          -not -path '*/README.md'
          -not -path "$root_dir/src/*"
          -not -path "$root_dir/target/*"
          -not -path "$root_dir/Bashbox.meta"
          -not -path "$root_dir/install.sh"
          -not -path "$root_dir/.dotfiles"
        );

        if test -n "${ignore:-}"; then {
          for _ignore_thing in "${ignore[@]}"; do {
            _ignore_thing="$root_dir/${_ignore_thing}";
            _ignore_thing="${_ignore_thing//\/\//\/}";
            _ignore_list+=(-not -path "$_ignore_thing");
          } done
          unset _ignore_thing;
        } fi

        local target_file target_dir;
        while read -r _file; do {
          file_name="${_file#"${root_dir}"/}";
          target_file="$installation_target/${file_name}";
          target_dir="${target_file%/*}";

          if test -e "$target_file" && {
            if test -L "$target_file"; then {
              test "$(readlink "$target_file")" != "$_file"
            } fi
          }; then {
            # Preserving host config strategy
            case "$file_name" in
              ".bashrc"|".bash_profile"|".zshrc"|".zprofile"|".kshrc"|".profile"|"config.fish")
                log::info "Your $file_name is being virtually loaded into the existing host $target_file";
                if test "$file_name" != "config.fish"; then {
                  local check_str="if test -e '$_file'; then source '$_file'; fi";
                } else {
                  local check_str="if test -e '$_file'; source '$_file'; end";
                } fi
                if ! grep -q "$check_str" "$target_file"; then {
                  printf '%s\n' "$check_str" >> "$target_file";
                } fi
                continue; # End this loop
              ;;
              ".gitconfig")
                log::info "Your $file_name is being merged with the existing host $file_name";
                local check_str="# dotsh merged";
                if ! grep -q "$check_str" "$target_file" 2>/dev/null; then {
                  # The native `[include.path]` doesn't seem to work as expected, so yeah...
                  printf '%s\n' \
                    "$check_str" \
                    "$(< "$_file")" \
                    "$check_str" >> "$target_file";
                } fi
                continue; # End this loop
              ;;
            esac
          } fi

          if test ! -d "$target_dir"; then {
            mkdir -p "$target_dir";
          } fi

          ln -sf "$_file" "$target_file";
          printf '%s\n' "$target_file" >> "$last_applied_filelist";
          unset target_file target_dir;
        } done < <(find "$root_dir" -type f "${_ignore_list[@]}");

      } done

		} fi
	} done
}

function dotfiles::use_chezmoi() {
  declare target="$1";

  if ! command::exists chezmoi; then {
    log::info "Installing chezmoi";
    declare bin="$HOME/.local/bin/chezmoi";
    declare url="https://git.io/chezmoi";
    mkdir -p "${bin%/*}";

    if command::exists curl; then {
      : "curl -fsLS";
    } elif command::exists wget; then {
      : "wget -qO-";
    } else {
      log::error "curl or wget wasn't found, chezmoi installation failed" 1 || exit;
    } fi

    sh -c "$($_ https://git.io/chezmoi)" -- -b "${bin%/*}" >/dev/null 2>&1;

  } fi

  chezmoi init --apply --source="${target}" || true;
}
