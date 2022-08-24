function install::userland_tools {
    log::info "Installing userland tools";

	# Just put all sorts of commands one by one here.

	# Install bashbox
	curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall &

	# Install stuff with brew
	local brew_pkgs=(
		"neovim"
		"bat"
		"exa"
	)
	log::info "Installing packages with brew";
	brew install "${brew_pkgs[@]}" &

	wait;
}
