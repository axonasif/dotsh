function config::neovim() {
	log::info "Installing and setting up Neovim";
	local nvim_conf_dir="$HOME/.config/nvim";
	if test -e "$nvim_conf_dir" && nvim_conf_bak="${nvim_conf_dir}.bak"; then {
		mv "$nvim_conf_dir" "$nvim_conf_bak";
	} fi

	curl -Ls "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz" \
		| sudo tar -C /usr --strip-components=1 -xpzf -

	git clone --filter=tree:0 https://github.com/axonasif/NvChad "$nvim_conf_dir" >/dev/null 2>&1;
	for _t in {1..2}; do {
		nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync';
	} done
	tmux send-keys -t "${tmux_first_session_name}:${tmux_first_window_num}" "nvim" Enter;

	# if test -e "$nvim_conf_bak"; then {
	# 	find "$nvim_conf_bak" -mindepth 1 -maxdepth 1
	# } fi
}