function config::neovim() {
	log::info "Configuring Neovim";
	local nvim_conf_dir="$HOME/.config/nvim";
	if test -e "$nvim_conf_dir" && nvim_conf_bak="${nvim_conf_dir}.bak"; then {
		mv "$nvim_conf_dir" "$nvim_conf_bak";
	} fi

	git clone --filter=tree:0 https://github.com/axonasif/NvChad "$nvim_conf_dir";
	wait::until_true command -v nvim 1>/dev/null;
	for _t in {1..2}; do {
		nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync';
	} done
	tmux send-keys -t "${tmux_first_session_name}:${tmux_first_window_num}" "nvim" Enter;

	# if test -e "$nvim_conf_bak"; then {
	# 	find "$nvim_conf_bak" -mindepth 1 -maxdepth 1
	# } fi
}