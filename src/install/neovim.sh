function install::neovim() {
	log::info "Installing and setting up Neovim";
	local nvim_conf_dir="$HOME/.config/nvim";
	if test -e "$nvim_conf_dir" && nvim_conf_bak="${nvim_conf_dir}.bak"; then {
		mv "$nvim_conf_dir" "$nvim_conf_bak";
	} fi

	curl -Ls "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz" \
		| sudo tar -C /usr --strip-components=1 -xpzf -;

	# Install LunarVim as an example config
	# git clone --filter=tree:0 https://github.com/axonasif/NvChad "$nvim_conf_dir" >/dev/null 2>&1;
	curl -sL "https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh" | bash -s -- --no-install-dependencies -y >/dev/null 2>&1;

	# for _t in {1..2}; do {
	# 	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 1>/dev/null;
	# } done

	# Wait for tmux to start
	await::signal get config_tmux;
	await::until_true tmux list-session >/dev/null 2>&1;

	# Run 'nvim --version' on tmux first window
	tmux send-keys -t "${tmux_first_session_name}:${tmux_first_window_num}" "nvim --version" Enter;
}