function config::editor() {
	log::info "Setting up editor preset";

	if editor::is "emacs"; then {
		case "${DOTFILES_EDITOR_PRESET:-spacemacs}" in
			"spacemacs")
				editor::emacs::space;
			;;
			"doomemacs")
				editor::emacs::doom;
			;;
		esac
	} elif editor::is "neovim"; then {
		case "${DOTFILES_EDITOR_PRESET:-lunarvim}" in
			"lunarvim")
				editor::neovim::lunar;
			;;
			"nvchad")
				editor::neovim::nvchad;
			;;
		esac
	} fi
}

function editor::is() {
	local target="$1";
	test "${DOTFILES_EDITOR:-neovim}" == "$target";
}

function editor::autorun_in_tmux() {
	(
		# Wait for tmux to start
		if test "${DOTFILES_TMUX:-true}" != true; then {
			return
		} fi
		await::signal get config_tmux_session;
		# until pgrep lvim 1>/dev/null; do
		tmux send-keys -t "${tmux_first_session_name}:${tmux_first_window_num}" "$@" Enter;
	) &
}

function editor::emacs::doom {
	todo;
}

function editor::emacs::space {
	declare clone_dir="$HOME/.emacs.d";
	await::signal get install_dotfiles;

	if test -e "$clone_dir/.git"; then {
		log::warn "$clone_dir already exists, not making any changes";
		return 0;
	} fi

	git clone --depth 1 https://github.com/syl20bnr/spacemacs "$clone_dir" 1>/dev/null;
	await::until_true test -x "$HOME/.nix-profile/bin/emacs";
	if is::cde; then {
		editor::autorun_in_tmux "emacs";
	} fi
}

function editor::neovim::lunar {
	# Wait for nix to complete installing neovim at userland_tools.sh:leveltwo_pkgs
	# if is::cde; then {
	# 	local check_file=(/nix/store/*-neovim-*/bin/nvim);
	# 	if test -n "${check_file:-}"; then {
	# 		await::create_shim "${check_file[1]}";
	# 	} else {
	# 		SHIM_MIRROR="$HOME/.nix-profile/bin/nvim" await::create_shim "/usr/bin/nvim";
	# 	} fi
	# } fi

	# local lvim_exec_path="/usr/bin/lvim";
	# if is::cde; then {
	# 	editor::autorun_in_tmux "AWAIT_SHIM_PRINT_INDICATOR=true lvim";
	# } fi

	# Install LunarVim as an example config
	if test ! -e "$HOME/.config/lvim"; then {

		# if is::cde; then {
		# 	NOCLOBBER=true KEEP=true SHIM_MIRROR="$HOME/.local/bin/lvim" await::create_shim "$lvim_exec_path";
		# } fi

		await::until_true command::exists git;
		await::until_true command::exists nvim;

		curl -sL "https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh" | bash -s -- --no-install-dependencies -y 1>/dev/null;
		
		# CLOSE=true await::create_shim "$lvim_exec_path";
		editor::autorun_in_tmux "lvim";
	} fi

	# for _t in {1..2}; do {
	# 	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 1>/dev/null;
	# } done
}

function editor::neovim::nvchad {
	todo;
}
