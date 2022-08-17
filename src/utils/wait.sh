function wait::for_file_existence() {
	local file="$1";
	until sleep 0.5 && test -e "$file"; do {
		continue;
	} done
}

function wait::for_vscode_ide_start() {
	if grep -q 'supervisor' /proc/1/cmdline; then {
		gp ports await 23000 1>/dev/null;
	} fi
}