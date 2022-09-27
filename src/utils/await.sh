function await::until_true() {
	local time="${TIME:-0.5}";
	local input=("$@");
	until "${input[@]}"; do {
		sleep "$time"
	} done
}

function await::while_true() {
	local time="${TIME:-0.5}";
	local input=("$@");
	while "${input[@]}"; do {
		sleep "$time"
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

	# shellcheck disable=SC2120
	function is::custom_shim() {
		test -v CUSTOM_SHIM_SOURCE;
	}

	function revert_shim() {
		if ! is::custom_shim; then {
			if test -e "$shim_source"; then {
				try_sudo mv "$shim_source" "$target";
			} fi
		} else {
			try_sudo mv "$shim_source" "$CUSTOM_SHIM_SOURCE";
			try_sudo rm "$target";
		} fi
		try_sudo rmdir --ignore-fail-on-non-empty "$shim_dir" 2>/dev/null || :;
		unset KEEP_internal_call CUSTOM_SHIM_SOURCE;	
	}

	# shellcheck disable=SC2120
	function create_self() {
		cmd() {
			printf '%s\n' '#!/usr/bin/env bash' "$(declare -f main)" 'main "$@"'
		}
		if ! test -v NO_PRINT; then {
			cmd > "${1:-"${BASH_SOURCE[0]}"}";
		} else {
			cmd
		} fi
	}

	local target shim_source;
	if test -v CUSTOM_SHIM_SOURCE; then
		export CUSTOM_SHIM_SOURCE="${CUSTOM_SHIM_SOURCE:-}"; # Reuse previoulsy exported CUSTOM_SHIM_SOURCE before CLOSE'ing
	fi

	for target in "$@"; do {

		if ! is::custom_shim; then {
			shim_dir="${target%/*}/.ashim";
			shim_source="${shim_dir}/${target##*/}";
		} else {
			shim_dir="${CUSTOM_SHIM_SOURCE%/*}/.cshim";
			shim_source="$shim_dir/${CUSTOM_SHIM_SOURCE##*/}";
		} fi

		if test -v CLOSE; then {
			revert_shim;
			return;
		} fi

		if test -e "$target"; then {
			log::warn "${FUNCNAME[0]}: $target already exists";
			if ! is::custom_shim; then {
				try_sudo mv "$target" "$shim_source";
			} fi
		} fi

		local USER && USER="$(id -u -n)";
		try_sudo sh -c "touch \"$target\" && chown $USER:$USER \"$target\"";

		# Embedded script
		function async_wrapper() {
			if test -v DEBUG_TUX; then
				set -x
			fi
			set -eu;

			diff_target="/tmp/.diff_${RANDOM}.${RANDOM}";
			if test ! -e "$diff_target"; then {
				create_self "$diff_target";
			} fi

			await_for_no_open_writes() {
				while lsof -F 'f' -- "$1" 2>/dev/null | grep -q '^f.*w$'; do
					sleep 0.5${RANDOM};
				done
			}

			await_while_shim_exists() {
				# if is::custom_shim; then {
				# 	: "$target"; # We could techincally only check for shim_source
				# } else {
				# 	: "$shim_source";
				# } fi
				: "$shim_source";

				local checkf="$_";
				TIME="0.5${RANDOM}" await::while_true test -e "$checkf";
			}

			if test -v AWAIT_SHIM_PRINT_INDICATOR; then {
				printf 'info[shim]: Loading %s\n' "$target";
			} fi

			# Initial loop for detecting $target modifications
			## For KEEP=
			if test "${KEEP_internal_call:-}" == true && test -e "$shim_source"; then {
				# When it's not the first time it was called, basically (2nd)
				exec "$shim_source" "$@";
			## For KEEP=
			} elif test -e "$shim_source"; then {
				# For external calls (2nd)
				await_while_shim_exists;
			} elif ! is::custom_shim; then {
				TIME="0.5${RANDOM}" await::while_true cmp --silent -- "$target" "$diff_target";
				TIME="0.5${RANDOM}" await_for_no_open_writes "$target";
			} else {
				TIME="0.5${RANDOM}" await::for_file_existence "$CUSTOM_SHIM_SOURCE";
				await_for_no_open_writes "$CUSTOM_SHIM_SOURCE";
			} fi


			# For KEEP=
			if test -v KEEP_internal_call; then {
				# Create shim
				if test "${KEEP_internal_call:-}" == true; then {

					if test ! -e "$shim_source"; then {
						try_sudo mkdir -p "${shim_source%/*}";

						if ! is::custom_shim; then {
							try_sudo mv "$target" "$shim_source";
							try_sudo env self="$(NO_PRINT=true create_self)" target="$target" sh -c 'printf "%s\n" "$self" > "$target" && chmod +x $target';
						} else {
							try_sudo mv "${CUSTOM_SHIM_SOURCE}" "$shim_source";
						} fi

					} fi

				# } else {
				# 	until test -e "$shim_source" || test -e "${CUSTOM_SHIM_SOURCE:-}"; do {
				# 		sleep 0.5${RANDOM}
				# 	} done
				} fi

				if test "${KEEP_internal_call:-}" == true; then {
					# For internal calls
					exec "$shim_source" "$@";
				} else {
					# For external calls
					await_while_shim_exists;
				} fi

			} fi

			# At this point it's not not an KEEP_internal_call=true thing
			if is::custom_shim; then {
				# We need to revert some magic manually here for external calls when KEEP= wasn't used
				# if ! test -v KEEP_internal_call; then
				# 	revert_shim;
				# fi
				target="$CUSTOM_SHIM_SOURCE"; # Set target to CUSTOM_SHIM_SOURCE
			} fi

			exec "$target" "$@";
		}


		# Async shim script creation
		{
			printf 'function main() {\n';
			printf '%s="%s"\n' \
								target "$target" \
								shim_source "$shim_source" \
								shim_dir "$shim_dir";
			if test -v CUSTOM_SHIM_SOURCE; then {
				printf '%s="%s"\n' CUSTOM_SHIM_SOURCE "$CUSTOM_SHIM_SOURCE";
			} fi
			# For KEEP=
			if test -v KEEP; then {
				printf '%s="%s"\n' "KEEP_internal_call" '${KEEP_internal_call:-false}';
				export KEEP_internal_call=true;
			} fi

			printf '%s\n' "$(declare -f await::while_true await::until_true await::for_file_existence sleep is::custom_shim try_sudo create_self async_wrapper)";
			printf '%s\n' 'async_wrapper "$@"; }';
		} > "$target";

		(
			source "$target";
			create_self "$target";
		)

		chmod +x "$target";
	} done
}
