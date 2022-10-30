function config::fish() {
	# Install fisher plugin manager
	log::info "Installing fisher and some plugins for fish-shell";

	await::until_true command -v fish 1>/dev/null;
	mkdir -p "$fish_confd_dir";
	{
		fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher';

		# Fisher plugins
		# fish -c 'fisher install lilyball/nix-env.fish'; # Might not be necessary because of my own .config/fish/conf.d/bash_env.fish
	} >/dev/null 2>&1
}