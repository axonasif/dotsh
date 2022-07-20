function tmux::setup() {
    local target="$HOME/.tmux/plugins/tpm";
    if test ! -e "$target"; then {
        git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target";
        bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh";
    } fi
}