
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


	# Install LunarVim as an example config
	if test ! -e "$HOME/.config/lvim"; then {
		local lvim_exec_path="/usr/bin/lvim";

		if is::cde; then {
			NOCLOBBER=true KEEP=true SHIM_MIRROR="$HOME/.local/bin/lvim" await::create_shim "$lvim_exec_path";
			(
				"$lvim_exec_path" -v >/dev/null 2>&1 & disown
				# Wait for tmux to start
				await::signal get config_tmux_session;
				# until pgrep lvim 1>/dev/null; do
				tmux send-keys -t "${tmux_first_session_name}:${tmux_first_window_num}" "AWAIT_SHIM_PRINT_INDICATOR=true lvim" Enter;
			) &
		} fi

		await::until_true command -v git 1>/dev/null;
		await::until_true command -v $HOME/.nix-profile/bin/nvim 1>/dev/null;

		curl -sL "https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh" | bash -s -- --no-install-dependencies -y 1>/dev/null;
		
		CLOSE=true await::create_shim "$lvim_exec_path";
	} fi

	# for _t in {1..2}; do {
	# 	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 1>/dev/null;
	# } done

}