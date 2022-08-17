function wait::for_file_existence() {
	local file="$1";
	until sleep 0.5 && test -e "$file"; do {
		continue;
	} done
}

function wait::for_vscode_ide_start() {
	gp ports await 23000 1>/dev/null;
}