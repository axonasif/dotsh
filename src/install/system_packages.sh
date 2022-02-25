_system_packages=(
    shellcheck
    rsync
    tree
)

function install::system_packages { (
    sudo install-packages "${_system_packages[@]}" 1>/dev/null;
) & }
