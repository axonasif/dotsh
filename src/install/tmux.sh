function install::tmux() {
	log::info "Setting up tmux";
    local target="$HOME/.tmux/plugins/tpm";
    if test ! -e "$target"; then {
        {
			git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target" >/dev/null 2>&1;
			wait::for_file_existence "/usr/bin/tmux";
			bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh";
		} 1>/dev/null
    } fi
}