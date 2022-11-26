function get::task_cmd() {
	local task="$1";
	local cmdc;
	local cmdc_tmp_file="/tmp/.dotfiles_task_cmd.$((RANDOM * $$))";
	IFS='' read -rd '' cmdc <<CMDC || :;
function ___exit_callback() {
	local r=\$?;
	rm -f "$cmdc_tmp_file" 2>/dev/null || true;
	if test -z "\${___manual_exit:-}"; then {
		exec '$(get::default_shell)' -il;
	} else {
		printf "\n${BRED}>> This task issued manual 'exit' with return code \$r${RC}\n";
		printf "${BRED}>> Press Enter or Return to dismiss${RC}" && read -r -n 1;
	} fi
}
function exit() {
	___manual_exit=true;
	command exit "\$@";
}; export -f exit;
trap "___exit_callback" EXIT;
printf "$BGREEN>> Executing task in bash:$RC\n";
IFS='' read -rd '' lines <<'EOF' || :;
$task
EOF
printf '%s\n' "\$lines" | while IFS='' read -r line; do
	printf "    ${YELLOW}%s${RC}\n" "\$line";
done
# printf '\n';
$task
CMDC

	if test "${#cmdc}" -gt 4096; then {
		printf '%s\n' "$cmdc" > "$cmdc_tmp_file";
		cmdc="$(
			printf 'eval "$(< "%s")"\n' "$cmdc_tmp_file";
		)";
	} fi

	printf '%s\n' "$cmdc";
}
