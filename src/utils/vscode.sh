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