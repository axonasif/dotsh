function config::shell::zsh {
    # Lock binary
    KEEP=true MONITOR_SHIM=true SHIM_MIRROR="/nix/store/*-zsh-*/bin/zsh" await::create_shim "/usr/bin/zsh";

    # Install ohmyzsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";

    CLOSE=true await::create_shim "/usr/bin/zsh";
}