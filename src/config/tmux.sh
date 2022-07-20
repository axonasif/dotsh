function tmux::setup() {
    local target="$HOME/.tmux/plugins/tpm";
    if test ! -e "$target"; then {
        git clone https://github.com/tmux-plugins/tpm "$target";
        bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh";
    } fi
}