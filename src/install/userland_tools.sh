function install::userland_tools {
    log::info "Installing userland tools"; (
        # Install bashbox
        curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall;

        # Install ranger-fm
        pip install --no-input ranger-fm;
) & }
