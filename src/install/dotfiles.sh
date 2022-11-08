function install::dotfiles() {
    log::info "Installing dotfiles";

    #  WHERE-TO         FUNCTION                SOURCES
    TARGET="$HOME" dotfiles::initialize "${dotfiles_repos[@]}";

    await::signal send install_dotfiles;
}
