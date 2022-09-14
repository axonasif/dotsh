function config::fish() {
	# Install fisher plugin manager
	log::info "Installing fisher and some plugins for fish-shell";
	wait::until_true command -v fish 1>/dev/null;
	fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher';

	# Fisher plugins
	fish -c 'fisher install acomagu/fish-async-prompt';
}