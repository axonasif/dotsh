function install::userland_tools {
    log::info "Installing userland tools";

	# Just put all sorts of commands one by one here.

	# Install bashbox
	curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall;
}
