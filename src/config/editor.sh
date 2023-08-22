function config::editor() {
    await::signal get install_dotfiles;
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
        editor::autorun_in_tmux "$HOME/.nix-profile/bin/emacs";
    } elif editor::is "neovim"; then {
        case "${DOTFILES_EDITOR_PRESET:-lunarvim}" in
            "lunarvim")
                editor::neovim::lunar;
            ;;
            "nvchad")
                editor::neovim::nvchad;
            ;;
        esac
        
        if ! command::exists lvim; then {
            editor::autorun_in_tmux "nvim";
        } fi

    } fi
}

function editor::is() {
    local target="$1";
    test "${DOTFILES_EDITOR:-neovim}" == "$target";
}

function editor::autorun_in_tmux() {
    declare command="$1";

    if is::cde && test "${DOTFILES_TMUX:-true}" = true; then {
        (
            await::signal get config_tmux_session;
            await::until_true command::exists "$command";
            tmux send-keys -t "${tmux_first_session_name}:${tmux_first_window_num}" "$command" Enter;
        ) &
    } fi
}

function editor::emacs::doom {
    return;
}

function editor::emacs::space {
    declare clone_dir="$HOME/.emacs.d";

    if test -e "$clone_dir/"; then {
        log::warn "$clone_dir already exists, not going to install any preset";
    } else {
        git clone --depth 1 https://github.com/syl20bnr/spacemacs "$clone_dir" 1>/dev/null;
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
    if test -e "$HOME/.config/nvim"; then {
        log::warn "~/.config/nvim exists, so not installing any preset";
    } else {
        # if is::cde; then {
        # 	NOCLOBBER=true KEEP=true SHIM_MIRROR="$HOME/.local/bin/lvim" await::create_shim "$lvim_exec_path";
        # } fi

        await::until_true command::exists git;
        await::until_true command::exists nvim;

        curl    -s https://raw.githubusercontent.com/lunarvim/lunarvim/release-1.3/neovim-0.9/utils/installer/install.sh \
        | sed   -e '/for dir in "${__lvim_dirs\[@\]}"; do/a if test "$dir" == "$HOME/.config/lvim"; then continue; fi' \
                -e '/function __backup_dir() {/a if test "$1" == "$HOME/.config/lvim"; then return; fi' \
        | LV_BRANCH='release-1.2/neovim-0.8' bash -s -- --no-install-dependencies -y;

        editor::autorun_in_tmux "lvim";
    } fi

  # CLOSE=true await::create_shim "$lvim_exec_path";

    # for _t in {1..2}; do {
    # 	nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 1>/dev/null;
    # } done
}

function editor::neovim::nvchad {
    return;
}
