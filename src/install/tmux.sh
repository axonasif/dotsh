function tmux::setup() {
	log::info "Setting up tmux";
    local target="$HOME/.tmux/plugins/tpm";
    if test ! -e "$target"; then {
        {
			git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target";
			until command -v tmux; do sleep 0.5; done # Wait until tmux is installed
			bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh";
		} 1>/dev/null
    } fi
}