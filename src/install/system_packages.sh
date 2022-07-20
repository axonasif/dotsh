_system_packages=(
    shellcheck
    rsync
    tree
)

function install::system_packages {
    log::info "Installing system packages in the background"; (
    sudo install-packages "${_system_packages[@]}" 1>/dev/null;
) & }
