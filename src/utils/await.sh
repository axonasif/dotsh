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
	declare -a vars_to_unset=(SHIM_MIRROR KEEP_internal_call);
	declare +x CLOSE KEEP DIRECT_CMD; # Keep local, do not export into env
	declare -x SHIM_MIRROR; # Keep SHIM_MIRROR exported until CLOSE'ed

	# shellcheck disable=SC2120
	function is::custom_shim() {
		test -v SHIM_MIRROR;
	}

	function revert_shim() {
		if test -e "$shim_source"; then {
			unset "${vars_to_unset[@]}";
			unset -f "$target_name";
			export PATH="${PATH//"${shim_dir}:"/}";
			
			try_sudo touch "$shim_tombstone";

			if ! is::custom_shim; then {
				try_sudo mv "$shim_source" "$target";
			} else {
				try_sudo mv "$shim_source" "$SHIM_MIRROR";
				try_sudo ln -sf "$SHIM_MIRROR" "$target";

			} fi
			(
				sleep 3;
				try_sudo rm -f "$shim_tombstone" || true;
				# if is::custom_shim; then {
				# 	try_sudo rm -f "$target" || true;
				# } fi
				try_sudo rmdir --ignore-fail-on-non-empty "$shim_dir" 2>/dev/null || :;
			) & disown;
		} fi
	}

	# shellcheck disable=SC2120
	function create_self() {
		declare +x NO_PRINT;
		cmd() {
			printf '%s\n' '#!/usr/bin/env bash' "$(declare -f main)" 'main "$@"'
		}
		if ! test -v NO_PRINT; then {
			cmd > "${1:-"${BASH_SOURCE[0]}"}";
		} else {
			cmd
		} fi
	}

	declare shim_dir shim_source shim_tombstone target="$1";
	declare target_name="${target##*/}";
	if ! is::custom_shim; then {
		shim_dir="${target%/*}/.ashim";
		shim_source="${shim_dir}/${target##*/}";
	} else {
		shim_dir="${SHIM_MIRROR%/*}/.cshim";
		shim_source="$shim_dir/${SHIM_MIRROR##*/}";
	} fi
	shim_tombstone="${shim_source}.tombstone";

	if test -v CLOSE; then {
		revert_shim;
		return;
	} fi
	
	if test -v KEEP && test ! -v KEEP_internal_call; then {
		export SHIM_SOURCE="$shim_source";
		export KEEP_internal_call=true;
	} fi

	if ! [[ "$PATH" =~ "$shim_dir" ]]; then {
		export PATH="$shim_dir:$PATH";
		fn="$(
			cat <<-EOF
			function $target_name() {
				if test -x "$shim_source"; then {
					declare +x ${vars_to_unset[@]};
					command "$shim_source" "\$@";
				} else {
					command "$target" "\$@";
				} fi
			}
			EOF
		)" && eval "$fn" && unset fn && export -f "${target_name}";
	} fi
	
	if test -v DIRECT_CMD; then {
		if shift; then {
			declare +x "${vars_to_unset[@]}";
			"$@";
		} fi
		return;
	} fi

	if test -e "$target" || test -e "${SHIM_MIRROR:-}"; then {
		# log::warn "${FUNCNAME[0]}: $target already exists";
		# return 0;
		try_sudo mkdir -p "$shim_dir";
		if ! is::custom_shim; then {
			try_sudo mv "$target" "$shim_source";
		} else {
			try_sudo mv "$SHIM_MIRROR" "$shim_source";
		} fi
	} fi

	declare USER && USER="$(id -u -n)";
	try_sudo sh -c "touch \"$target\" && chown $USER:$USER \"$target\"";

	# Embedded script
	function async_wrapper() {
		# DEBUG
		# if test -v DEBUG_TUX; then
		# 	set -x;
		# fi
		set -eu;

		# DEBUG
		# if test "${KEEP_internal_call:-}" == false; then {
		# 	trap 'printf "[%s]: %s\n" "${LINENO}" "$BASH_COMMAND" >> /tmp/log' DEBUG;
		# } fi

		# TODO: Improve this, too many garbage left behind
		diff_target="/tmp/.diff_${RANDOM}.${RANDOM}";
		if test ! -e "$diff_target"; then {
			create_self "$diff_target";
		} fi

		await_for_no_open_writes() {
			while lsof -F 'f' -- "$1" 2>/dev/null | grep -q '^f.*w$'; do
				sleep 0.5${RANDOM};
			done
		}

		exec_bin() {
			local args=("$@");
			local bin="${args[0]}";
			await::until_true test -x "$bin";
			exec "${args[@]}";
		}

		await_while_shim_exists() {
			# DEBUG
			# if test "${KEEP_internal_call:-}" == false; then set -x; fi

			# Refer to revert_shim for this if-code-block
			# if is::custom_shim; then {
			#	: "$target";
			# } else {
				: "$shim_source";
			# } fi

			local checkf="$_";

			for _i in {1..3}; do {
				sleep 0.2${RANDOM};
				TIME="0.5${RANDOM}" await::while_true test -e "$checkf";
				# DEBUG
				# while test -e "$checkf"; do {
					# if test "${KEEP_internal_call:-}" == false; then
					# 	printf '============ %s\n' "CHEKF=$checkf" "$(ls "$target" ||:;)" "$(ls "$shim_source" ||:;)"
					# fi
					# sleep 0.5$RANDOM;
				# } done
				
			} done

		}

		if test -v AWAIT_SHIM_PRINT_INDICATOR; then {
			printf 'info[shim]: Loading %s\n' "$target";
		} fi

		# Initial loop for detecting $target modifications
		## For KEEP=
		if test -e "$shim_source"; then {
			if test "${KEEP_internal_call:-}" == true; then {
				# When it's not the first time it was called, basically (2nd)
				exec_bin "$shim_source" "$@";
			} else {
				## For KEEP=
				# For external calls (2nd)
				await_while_shim_exists;
			} fi
		} elif ! is::custom_shim; then {
			TIME="0.5${RANDOM}" await::while_true cmp --silent -- "$target" "$diff_target";
			rm -f "$diff_target" 2>/dev/null || :;
			TIME="0.5${RANDOM}" await_for_no_open_writes "$target";
		} else {
			TIME="0.5${RANDOM}" await::for_file_existence "$SHIM_MIRROR";
			await_for_no_open_writes "$SHIM_MIRROR";
		} fi


		# For KEEP=
		if test -v KEEP_internal_call; then {
			# Create shim
			if test "${KEEP_internal_call:-}" == true; then {

				# For internal calls
				if test ! -e "$shim_tombstone" && test ! -e "$shim_source"; then {
						try_sudo mkdir -p "${shim_source%/*}";

						if ! is::custom_shim; then {
							try_sudo mv "$target" "$shim_source";
							try_sudo env self="$(NO_PRINT=true create_self)" target="$target" sh -c 'printf "%s\n" "$self" > "$target" && chmod +x $target';
						} else {
							try_sudo mv "${SHIM_MIRROR}" "$shim_source";
						} fi
				} fi

				if test -e "$shim_source"; then {
					exec_bin "$shim_source" "$@";
				} fi

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
			target="$SHIM_MIRROR"; # Set target to SHIM_MIRROR
		} fi

		exec_bin "$target" "$@";
	}

	# Async shim script creation
	{
		printf 'function main() {\n';
		printf '%s="%s"\n' \
							target "$target" \
							shim_source "$shim_source" \
							shim_dir "$shim_dir";
		if test -v SHIM_MIRROR; then {
			printf '%s="%s"\n' SHIM_MIRROR "$SHIM_MIRROR";
		} fi
		# For KEEP=
		if test -v KEEP; then {
			printf '%s="%s"\n' \
								"KEEP_internal_call" '${KEEP_internal_call:-false}' \
								shim_tombstone "$shim_tombstone";
		} fi

		printf '%s\n' "$(declare -f await::while_true await::until_true await::for_file_existence sleep is::custom_shim try_sudo create_self async_wrapper)";
		printf '%s\n' 'async_wrapper "$@"; }';
	} > "$target";

	(
		source "$target";
		create_self "$target";
	)

	chmod +x "$target";
}
