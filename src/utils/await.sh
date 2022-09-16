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
	function try_sudo() {
		{ "$@" || sudo "$@"; } 2>/dev/null;
	}

	local target shim_source;
	local internal_var_name="DOTFILES_INTERNAL_SHIM_CALL";

	for target in "$@"; do {
		shim_dir="${target%/*}/.shim";
		shim_source="${shim_dir}/${target##*/}";
		try_sudo mkdir -p "$shim_dir";

		if test -v CLOSE; then {
			unset "$internal_var_name";
			if test -e "$shim_source"; then {
				try_sudo mv "$shim_source" "$target";
				rmdir --ignore-fail-on-non-empty "$shim_dir" 2>/dev/null || :;
			} fi
			return;
		} fi

		if test -e "$target"; then {
			log::warn "${FUNCNAME[0]}: $target already exists";
			try_sudo mv "$target" "$shim_source";
		} fi

		if ! touch "$target" 2>/dev/null; then {
			local USER && USER="$(id -u -n)";
			sudo bash -c "touch \"$target\" && chown -h $USER:$USER \"$target\"";
		} fi

		cat > "$target" <<'SCRIPT'
#!/usr/bin/env bash
set -eu;
self="$(<"$0")"
function main() {
	if test -v "$internal_var_name" && test -e "$shim_source"; then {
		exec "$shim_source" "$@";
	} fi

	diff_target="/tmp/.diff_${RANDOM}.${RANDOM}";
	if test ! -e "$diff_target"; then {
		cp "$target" "$diff_target";
	} fi

	if test -v PRINT_INDICATOR; then {
		printf 'info[shim]: Loading %s\n' "$target";
	} fi

	function await() {
		while cmp --silent -- "$target" "$diff_target"; do {
			sleep 0.2;
		} done

		while lsof -F 'f' -- "$target" 2>/dev/null | grep -q '^f.*w$'; do {
			sleep 0.2;
		} done
	}

	await;
SCRIPT

		if test -v KEEP; then {
			eval "export $internal_var_name=ture";
			cat >> "$target" <<'SCRIPT'
	# For internal calls
	if test -v $internal_var_name; then {
		if test ! -e "$shim_source"; then {
			sudo mv "$target" "$shim_source";
			sudo env self="$self" target="$target" bash -c 'printf "%s\n" "$self" > "$target" && chmod +x $target';
		} fi
		exec "$shim_source" "$@";
	} fi

	# For external calls
	while test -e "$shim_source"; do {
		sleep 0.2;
	} done
SCRIPT
		} fi

		# Script closing
		{
			printf '\texec %s "$@"\n\n}\n\n' "$target";
			printf '%s="%s"\n' \
								target "$target" \
								shim_source "$shim_source" \
								internal_var_name "$internal_var_name";

			printf '%s\n' "$(declare -f sleep)";
			printf 'main "$@"\n';
		} >> "$target";
		chmod +x "$target";
	} done
}
