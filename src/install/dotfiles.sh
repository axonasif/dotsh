function install::dotfiles() {
    log::info "Installing public dotfiles";
    REPO="${DOTFILES_PRIMARY_REPO:-}" dotfiles::initialize;

    # log::info "Installing private dotfiles";
    # REPO="https://github.com/axonasif/dotfiles.private" dotfiles::initialize & disown;

    await::signal send install_dotfiles;
}
