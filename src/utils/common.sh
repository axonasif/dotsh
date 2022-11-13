use libtmux::common;

function is::gitpod() {
      # Check for existent of this gitpod-specific file and the ENV var.
      test -e /usr/bin/gp && test -v GITPOD_REPO_ROOT;
}

function is::codespaces() {
	test -v CODESPACES || test -e /home/codespaces;
}

function is::cde {
	is::gitpod || is::codespaces;
}

function try_sudo() {
	"$@" 2>/dev/null || sudo "$@";
}

function get::default_shell {

	await::signal get install_dotfiles;
	
	local custom_shell;
	if test "${DOTFILES_TMUX:-true}" == true; then {
		await::signal get config_tmux;
	} fi

	if test -n "${DOTFILES_SHELL:-}"; then {
		custom_shell="$(command -v "${DOTFILES_SHELL}")";

		if test "${DOTFILES_TMUX:-true}" == true; then {
			local tmux_shell;
			if tmux_shell="$(tmux::show-option default-shell)" \
			&& [ "$tmux_shell" != "$custom_shell" ]; then {
				(
					exec 1>&-;
					until tmux has-session 2>/dev/null; do {
						sleep 1;
					} done
					tmux set -g default-shell "$custom_shell" || :;
				) & disown;
			} fi
		} fi

	} elif test "${DOTFILES_TMUX:-true}" == true; then {
		if custom_shell="$(tmux::show-option default-shell)" \
		&& [ "${custom_shell}" == "/bin/sh" ]; then {
			custom_shell="$(command -v bash)";
		} fi

	} elif ! custom_shell="$(command -v fish)"; then {
		custom_shell="$(command -v bash)";
	} fi
	
	printf '%s\n' "${custom_shell:-/bin/bash}";
}

function command::exists() {
	declare cmd="$1";
	cmd="$(command -v "$cmd")" && test -x "$cmd";
}

function vscode::add_settings() {
	SIGNALS="RETURN ERR EXIT" lockfile "vscode_addsettings";
	await::until_true command::exists yq ;

	# Read from standard input
	read -t0.5 -u0 -r -d '' input || :
	if test -z "${input:-}"; then {
		return 1
	}; fi

	local settings_file
	for settings_file in "$@"; do {
		local tmp_file="${settings_file%/*}/.tmp$$"

		# Create the vscode machine settings file if it doesnt exist
		if test ! -e "$settings_file"; then {
			mkdir -p "${settings_file%/*}"
			touch "$settings_file"
		}; fi

		# Check json syntax
		if test ! -s "$settings_file" || ! yq -o=json -reM '""' "$settings_file" >/dev/null 2>&1; then {
			printf '%s\n' "$input" >"$settings_file"
		}; else {
			# Remove any trailing commas (not needed for yq)
			# sed -i -e 's|,}|\n}|g' -e 's|, }|\n}|g' -e ':begin;$!N;s/,\n}/\n}/g;tbegin;P;D' "$settings_file"

			# Merge the input settings with machine settings.json
			cp -a "$settings_file" "$tmp_file"
			# jq -s '.[0] * .[1]' - "$tmp_file" <<<"$input" >"$settings_file"
			yq ea -o=json -I2 -M '. as $item ireduce ({}; . * $item )' - "$tmp_file" <<<"$input" >"$settings_file"
			rm -f "$tmp_file"
		}; fi

	}; done

}

function dotfiles::initialize() {
	await::until_true command::exists git;
	
	local installation_target="${INSTALL_TARGET:-"$HOME"}";
	local last_applied_filelist="$installation_target/.last_applied_dotfiles";
	local 	dotfiles_repo \
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
			# Process .dotfiles ignore
			local _dotfiles_ignore="$source_dir/.dotfilesignore";
			local _thing_path;
			local _ignore_list=(
				-not -path '*/.git/*'
				-not -path '*/.dotfilesignore'
				-not -path '*/.gitpod*'
				-not -path '*/README.md'
				-not -path "$source_dir/src/*"
				-not -path "$source_dir/target/*"
				-not -path "$source_dir/Bashbox.meta"
				-not -path "$source_dir/install.sh"
			);

			if test -e "$_dotfiles_ignore"; then {
				while read -r _ignore_thing; do {
					if [[ ! "$_ignore_thing" =~ ^\# ]]; then {
						_ignore_thing="$source_dir/${_ignore_thing}";
						_ignore_thing="${_ignore_thing//\/\//\/}";
						_ignore_list+=(-not -path "$_ignore_thing");
					} fi
					unset _ignore_thing;
				} done < "$_dotfiles_ignore"
			} fi

			local target_file target_dir;
			while read -r _file; do {
				file_name="${_file#"${source_dir}"/}";
				target_file="$installation_target/${file_name}";
				target_dir="${target_file%/*}";

				if test -e "$target_file" && {
					if test -L "$target_file"; then {
						test "$(readlink "$target_file")" != "$_file"
					} fi
				}; then {
					# Preserving host config strategy
					case "$file_name" in
						".bashrc"|".zshrc"|".kshrc"|".profile")
							log::info "Your $file_name is being injected into the existing host $target_file";
							local check_str="if test -e '$_file'; then source '$_file'; fi";
							if ! grep -q "$check_str" "$target_file"; then {
								printf '%s\n' "$check_str" >> "$target_file";
							} fi
							continue; # End this loop
						;;
						".gitconfig")
							log::info "Your $file_name is being injected into the existing host $file_name";
							local check_str="    path = $_file";
							if ! grep -q "$check_str" "$target_file" 2>/dev/null; then {
								{
									printf '[%s]\n' 'include';
									printf '%s\n' "$check_str";
								} >> "$target_file";
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
			}  done < <(find "$source_dir" -type f "${_ignore_list[@]}");

		} fi
	} done
}
