function config::shell::zsh {
    use bashenv_zsh::lib;
    # Lock binary
    KEEP=true MONITOR_SHIM=true SHIM_MIRROR="/nix/store/*-zsh-*/bin/zsh" await::create_shim "/usr/bin/zsh";

    declare user_zshrc="$HOME/.zshrc";
    declare bashenv_data="$(
      func="$(declare -f bashenv.zsh)";
      func="${func#*{}";
      func="${func%\}}";

      printf '%s\n' "$func";
    )"

    if ! grep -q "$bashenv_data" "$user_zshrc" 2>/dev/null; then {
      printf '\n%s\n' "$bashenv_data" >> "$user_zshrc";
    } fi

    # Install ohmyzsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";

    CLOSE=true await::create_shim "/usr/bin/zsh";
}
