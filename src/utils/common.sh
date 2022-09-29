function is::gitpod() {
      # Check for existent of this gitpod-specific file and the ENV var.
      test -e /usr/bin/gp && test -v GITPOD_REPO_ROOT;
}

function is::codespaces() {
	test -v CODESPACES || test -e /home/codespaces;
}

function vscode::add_settings() {
	local lockfile="/tmp/.vscs_add.lock";
	local vscode_machine_settings_file="${SETTINGS_TARGET:-$vscode_machine_settings_file}";
	trap "rm -f $lockfile" ERR SIGINT RETURN;
	while test -e "$lockfile" && sleep 0.2; do {
		continue;
	} done
	touch "$lockfile";

	# TODO: Convert this into a stdlib (arg_or_stdin)
	local input="${1:-}";
	
	if test ! -n "$input"; then {
		# Read from standard input
		read -t0.5 -u0 -r -d '' input || :;
	} elif test -e "$input"; then {
		# Read the input file into a variable
		input="$(< "$input")";
	} else {
		log::error "$FUNCNAME: $input does not exist" || exit 1;
	} fi
	# TODOEND

	if test -n "${input:-}"; then {
		# Create the vscode machine settings file if it doesnt exist
		if test ! -e "$vscode_machine_settings_file"; then {
			mkdir -p "${vscode_machine_settings_file%/*}";
			touch "$vscode_machine_settings_file";
		} fi
		
		# Check json syntax
		await::until_true command -v jq 1>/dev/null;
		if test ! -s "$vscode_machine_settings_file"  || ! jq -reM '""' "$vscode_machine_settings_file" 1>/dev/null; then {
			printf '%s\n' "$input" > "$vscode_machine_settings_file";
		} else {
			# Remove any trailing commas
			sed -i -e 's|,}|\n}|g' -e 's|, }|\n}|g' -e ':begin;$!N;s/,\n}/\n}/g;tbegin;P;D' "$vscode_machine_settings_file";

			# Merge the input settings with machine settings.json
			local tmp_file="${vscode_machine_settings_file%/*}/.tmp";
			cp -a "$vscode_machine_settings_file" "$tmp_file";
			jq -s '.[0] * .[1]' - "$tmp_file" <<<"$input" > "$vscode_machine_settings_file";
		} fi

	} fi
}

function dotfiles::initialize() {
	local installation_target="${INSTALL_TARGET:-"$HOME"}";
	local last_applied_filelist="$installation_target/.last_applied_dotfiles";
	local dotfiles_repo local_dotfiles_repo_count;
	local repo_user repo_name source_dir repo_dir_name check_dir;
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
				-not -path "'*/.git/*'"
				-not -path "'*/.dotfilesignore'"
				-not -path "'*/.gitpod.yml'"
				-not -path "'$source_dir/src/*'"
				-not -path "'$source_dir/target/*'"
				-not -path "'$source_dir/Bashbox.meta'"
				-not -path "'$source_dir/install.sh'"
			);

			if test -e "$_dotfiles_ignore"; then {
				while read -r _ignore_thing; do {
					if [[ ! "$_ignore_thing" =~ ^\# ]]; then {
						_ignore_thing="$source_dir/${_ignore_thing}";
						_ignore_thing="${_ignore_thing//\/\//\/}";
						_ignore_list+=(-not -path "$_ignore_thing");
					} fi
					unset _ignore_thing;
					# _thing_path="$(readlink -f "$source_dir/$_ignore_thing")";
					# if test -f "$_thing_path"; then {
					#     _ignore_list+=("-not -path '$_thing_path'");
					# } elif test -d "$_thing_path"; then {
					#     _ignore_list+=("-not -path '/$_thing_path/*'");
					# } fi
				} done < "$_dotfiles_ignore"
			} fi

			local _target_file _target_dir;
			while read -r _file ; do {
				_target_file="$installation_target/${_file#${source_dir}/}";
				_target_dir="${_target_file%/*}";

				if test ! -d "$_target_dir"; then {
					mkdir -p "$_target_dir";
				} fi

				ln -sf "$_file" "$_target_file";
				printf '%s\n' "$_target_file" >> "$last_applied_filelist";
				unset _target_file _target_dir;
			}  done < <(printf '%s\n' "${_ignore_list[@]}" | xargs find "$source_dir" -type f);

		} fi
	} done
}