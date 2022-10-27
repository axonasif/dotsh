function install::misc {
    log::info "Installing misc tools";

	### Just put all sorts of commands one by one here.

	# Install bashbox
	(
		curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s -- selfinstall --no-modify-path >/dev/null 2>&1;
		
		if test -e "$HOME/.bashrc.d"; then {
			: ".bashrc.d";
		} elif test -e "$HOME/.shellrc.d"; then {
			: ".shellrc.d";
		} else {
			exit 0;
		} fi
		printf 'source %s\n' "$HOME/.bashbox/env" > "$HOME/$_/bashbox.bash";

	) & disown;

	
}
