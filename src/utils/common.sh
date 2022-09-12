function is::gitpod() {
      # Check for existent of this gitpod-specific file and the ENV var.
      test -e /ide/bin/gitpod-code && test -v GITPOD_REPO_ROOT;
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
		} fi
		
		# Check json syntax
		wait::for_file_existence "/usr/bin/jq";
		if test ! -s "$vscode_machine_settings_file"  || ! jq -reM '""' "$vscode_machine_settings_file" 1>/dev/null; then {
			printf '{}\n' > "$vscode_machine_settings_file";
		} fi

		# Remove any trailing commas
		sed -i -e 's|,}|\n}|g' -e 's|, }|\n}|g' -e ':begin;$!N;s/,\n}/\n}/g;tbegin;P;D' "$vscode_machine_settings_file";

		# Merge the input settings with machine settings.json
		local tmp_file="${vscode_machine_settings_file%/*}/.tmp";
		cp -a "$vscode_machine_settings_file" "$tmp_file";
		jq -s '.[0] * .[1]' - "$tmp_file" <<<"$input" > "$vscode_machine_settings_file";
		rm "$tmp_file";
	} fi
}

function dotfiles::initialize() {
	local _dotfiles_repo="${REPO:-"$___self_REPOSITORY"}";
	if is::gitpod; then {
		: "/tmp/.dotfiles_repo.${RANDOM}";
	} else {
		: "$HOME/.dotfiles-sh_${_dotfiles_repo##*/}";
	} fi
	local _generated_source_dir="";
	local _source_dir="${1:-"$_generated_source_dir"}";
	local _installation_target="${2:-"$HOME"}";
	local last_applied_filelist="$___self_DIR/.git/.last_applied";
	
	if test ! -e "$_source_dir"; then {
		git clone --filter=tree:0 "$_dotfiles_repo" "$_source_dir" > /dev/null 2>&1 || :;
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
	
	if test -e "$_source_dir" ; then {
		# Process .dotfiles ignore
		local _dotfiles_ignore="$_source_dir/.dotfilesignore";
		local _thing_path;
		local _ignore_list=(
			-not -path "'*/.git/*'"
			-not -path "'*/.dotfilesignore'"
			# -not -path "'*/.gitpod.yml'"
			-not -path "'$_source_dir/src/*'"
			-not -path "'$_source_dir/target/*'"
			-not -path "'$_source_dir/Bashbox.meta'"
			-not -path "'$_source_dir/install.sh'"
		);

		if test -e "$_dotfiles_ignore"; then {
			while read -r _ignore_thing; do {
				if [[ ! "$_ignore_thing" =~ ^\# ]]; then {
					_ignore_thing="$_source_dir/${_ignore_thing}";
					_ignore_thing="${_ignore_thing//\/\//\/}";
					_ignore_list+=(-not -path "$_ignore_thing");
				} fi
				unset _ignore_thing;
				# _thing_path="$(readlink -f "$_source_dir/$_ignore_thing")";
				# if test -f "$_thing_path"; then {
				#     _ignore_list+=("-not -path '$_thing_path'");
				# } elif test -d "$_thing_path"; then {
				#     _ignore_list+=("-not -path '/$_thing_path/*'");
				# } fi
			} done < "$_dotfiles_ignore"
		} fi

		# pushd "$_source_dir" 1>/dev/null;

	# Reset last_applied_filelist
		printf '' > "$last_applied_filelist";
		local _target_file _target_dir;
		while read -r _file ; do {
			_target_file="$_installation_target/${_file#${_source_dir}/}";
			_target_dir="${_target_file%/*}";
			if test ! -d "$_target_dir"; then {
				mkdir -p "$_target_dir";
			} fi
			# echo "s: $_file"
			# echo "t: $_target_file"
			ln -sf "$_file" "$_target_file";
			printf '%s\n' "$_target_file" >> "$last_applied_filelist";
			unset _target_file _target_dir;
		}  done < <(printf '%s\n' "${_ignore_list[@]}" | xargs find "$_source_dir" -type f);
		# popd 1>/dev/null;
	} fi
}