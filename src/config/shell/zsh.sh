function config::shell::zsh {
    # Lock binary
    await::create_shim_nix_common_wrapper "zsh";

    # Install ohmyzsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";
}