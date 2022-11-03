
function config::neovim() {
	log::info "Setting up Neovim";

	# Wait for nix to complete installing neovim at userland_tools.sh:leveltwo_pkgs
	# if is::cde; then {
	# 	local check_file=(/nix/store/*-neovim-*/bin/nvim);
	# 	if test -n "${check_file:-}"; then {
	# 		await::create_shim "${check_file[1]}";
	# 	} else {
	# 		SHIM_MIRROR="$HOME/.nix-profile/bin/nvim" await::create_shim "/usr/bin/nvim";
	# 	} fi
	# } fi

	await::until_true command -v git 1>/dev/null;
	await::until_true command -v $HOME/.nix-profile/bin/nvim 1>/dev/null;

	# Install LunarVim as an example config
	if test ! -e "$HOME/.config/lvim"; then {
		# git clone --filter=tree:0 https://github.com/axonasif/NvChad "$nvim_conf_dir" >/dev/null 2>&1;
		curl -sL "https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh" | bash -s -- --no-install-dependencies -y 1>/dev/null;
	} fi

	# for _t in {1..2}; do {
	# 	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 1>/dev/null;
	# } done

	if is::cde; then {
		# Wait for tmux to start
		await::signal get config_tmux_session;

		# # Run 'nvim --version' on tmux first window
		# until pgrep lvim 1>/dev/null; do
		tmux send-keys -t "${tmux_first_session_name}:${tmux_first_window_num}" "lvim" Enter;
	} fi
}