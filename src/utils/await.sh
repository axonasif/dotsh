function await::until_true() {
	local time="${TIME:-0.5}";
	local input=("$@");
	until sleep "$time" && "${input[@]}"; do {
		continue;
	} done
}

function await::for_file_existence() {
	local file="$1";
	await::until_true test -e "$file";
}

function await::for_vscode_ide_start() {
	if grep -q 'supervisor' /proc/1/cmdline; then {
		gp ports await 23000 1>/dev/null;
	} fi
}

function await::signal() {
	local kind="$1";
	local target="$2";
	local status_file="/tmp/.asignal_${target}";

	case "$kind" in
		"get")
			until test -s "$status_file"; do {
				sleep 0.2;
			} done
		;;
		send)
			printf 'done\n' >> "$status_file";
		;;
	esac
}

function await::create_shim() {
	local target shim_source;
	local internal_var_name="DOTFILES_INTERNAL_SHIM_CALL";

	for target in "$@"; do {
		shim_source="${target}.shim_source";

		if test -v CLOSE; then {
			if test -e "$shim_source"; then {
				sudo mv "$shim_source" "$target";
			} fi
			return;
		} fi

		if test -e "$target"; then {
			log::warn "${FUNCNAME[0]}: $target already exists";
			return;
		} fi

		if ! touch "$target" 2>/dev/null; then {
			local USER && USER="$(id -u -n)";
			sudo bash -c "touch \"$target\" && chown -h $USER:$USER \"$target\"";
		} fi


		cat > "$target" <<-SCRIPT
		#!/usr/bin/env bash
		{
		
		set -eu;

		set -x
		exec 2>>/tmp/lol

		shim_source="$shim_source";
		self="\$(<"$target")";

		$(declare -f sleep)

		if test ! -v $internal_var_name; then {
			printf 'info[shim]: Loading %s\n' "$target";
		} fi

		function await() {
			while printf '%s' "\$self" | cmp --silent -- - "$target"; do {
				sleep 0.2;
			} done

			while PID="\$(lsof -t "$target" 2>/dev/null)" || break; do {
				if test "\$PID" == \$\$; then {
					break;
				} fi
				sleep 0.2;
			} done
		}

		await;
		SCRIPT

		if test -v KEEP; then {
			eval "export $internal_var_name=ture";
			cat >> "$target" <<-SCRIPT
			# For internal calls
			if test -v $internal_var_name; then {
				if test ! -e "\$shim_source"; then {
					sudo mv "$target" "\$shim_source";
					sudo env self="\$self" bash -c 'printf "%s\n" "\$self" > "$target" && chmod +x $target';
				} fi
				exec "\$shim_source" "\$@";
			} fi

			# For external calls
			while test -e "\$shim_source"; do {
				sleep 0.2;
			} done
			SCRIPT
		} fi

		# Script closing
		printf 'exec %s "$@"\n\n}' "$target" >> "$target";
		chmod +x "$target";
	} done
}
