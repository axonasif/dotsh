function is::gitpod() {
      # Check for existent of this gitpod-specific file and the ENV var.
      test -e /ide/bin/gitpod-code && test -v GITPOD_REPO_ROOT;
}

function vscode::add_settings() {
	# TODO: Convert this into a stdlib (arg_or_stdin)
	local input="${1:-}";
	
	if test ! -n "$input"; then {
		# Read from standard input
		read -t0.1 -u0 -r -d '' input;
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

		# Remove any trailing commas
		sed -i -e 's|,}|\n}|g' -e 's|, }|\n}|g' -e ':begin;$!N;s/,\n}/\n}/g;tbegin;P;D' "$vscode_machine_settings_file";

		# Merge the input settings with machine settings.json
		local tmp_file="${vscode_machine_settings_file%/*}/.tmp";
		cp -a "$vscode_machine_settings_file" "$tmp_file";
		jq -s '.[0] * .[1]' - "$tmp_file" <<<"$input" > "$vscode_machine_settings_file";
		rm "$tmp_file";
	} fi
}

# Detect OS function