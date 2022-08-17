function install::tmux() {
	log::info "Setting up tmux";
    local target="$HOME/.tmux/plugins/tpm";
    if test ! -e "$target"; then {
        {
			git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target";
			wait::for_file_existence "$(command -v tmux)";
			bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh";
		} 1>/dev/null
    } fi
}