function install::dotfiles() {
    log::info "Installing public dotfiles";
    REPO="https://github.com/axonasif/dotfiles.public" dotfiles::initialize;

    # log::info "Installing private dotfiles";
    # REPO="https://github.com/axonasif/dotfiles.private" dotfiles::initialize & disown;
}
