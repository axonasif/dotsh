function install::dotfiles() {
    log::info "Installing dotfiles";

    # List all of your dotfiles repo links that you want to apply in the array below:
    local dotfiles_repos=(
        "${DOTFILES_PRIMARY_REPO:-https://github.com/axonasif/dotfiles.public}" # You can remove this line if you like
        # https://github.com/axonasif/dotfiles.private
    )

    #  WHERE-TO         FUNCTION                SOURCES
    TARGET="$HOME" dotfiles::initialize "${dotfiles_repos[@]}";

    await::signal send install_dotfiles;
}
