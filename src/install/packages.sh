function install::packages {
    # shellcheck disable=SC2034
    declare -a dw_cmd;
    if command::exists curl; then {
        dw_cmd=(curl -sSL);
    } elif command::exists wget; then {
        dw_cmd=(wget -qO-);
    } fi

    # =================================================
    # = assign dynamic packages                       =
    # =================================================
    if test "${DOTFILES_TMUX:-true}" == true; then {
        if is::cde && test -n "${dw_cmd[0]}"; then {
            (
                dw_path=/tmp/.tmuxdw;
                declare dw_url="https://github.com/axonasif/build-static-tmux/releases/latest/download/tmux.linux-amd64.stripped";
                "${dw_cmd[@]}" "${dw_url}" > "$dw_path";
                sudo sh -c "mv $dw_path /usr/bin/tmux && chmod +x /usr/bin/tmux";
                if ! command::exists jq; then {
                    dw_path=/tmp/.jqdw;
                    dw_url="https://github.com/stedolan/jq/releases/latest/download/jq-linux64";
                    "${dw_cmd[@]}" "$dw_url" > "$dw_path";
                    sudo sh -c "mv $dw_path /usr/bin/jq && chmod +x /usr/bin/jq";
                } fi
            ) & disown;
        } else {
            nixpkgs_level_one+=(nixpkgs.tmux nixpkgs.jq);
        } fi
    } fi

    nixpkgs_level_one+=(nixpkgs."${DOTFILES_SHELL:-fish}")

    case "${DOTFILES_EDITOR:-neovim}" in
        "emacs")
            nixpkgs_level_two+=("nixpkgs.emacs");
        ;;
        "helix")
            nixpkgs_level_two+=("nixpkgs.helix");
        ;;
        "neovim")
            if is::cde && test -n "${dw_cmd[0]}"; then {
                (
                    declare dw_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
                    "${dw_cmd[@]}" "${dw_url}" | sudo tar --strip-components=1 -C /usr -xpz;
                    # sudo chmod +x /usr/bin/nvim;
                ) & disown;
            } else {
                nixpkgs_level_two+=("nixpkgs-unstable.neovim");
            } fi
        ;;
    esac

    if ! command::exists git; then {
        nixpkgs_level_two+=(nixpkgs.git);
    } fi
    
    if is::gitpod; then {
        nixpkgs_level_two+=(nixpkgs."${gitpod_scm_cli}");
    } else {
        nixpkgs_level_two+=(
            nixpkgs.gh
            nixpkgs.glab
        )
    } fi

    if os::is_darwin; then {

        # Install brew if missing
        if test ! -e /opt/homebrew/Library/Taps/homebrew/homebrew-core/.git \
        && test ! -e /usr/local/Library/Taps/homebrew/homebrew-core/.git; then {
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
        } fi

        log::info "Installing userland packages with brew";
        if ! command::exists brew; then {
            PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"; # Intentionally low-prio
            eval "$(brew shellenv)";
        } fi

        for level in ${!brewpkgs_level_*}; do {
            declare -n ref="$level";
            if test -n "${ref:-}"; then {
                NONINTERACTIVE=1 brew install -q "${ref[@]}" || true; # Do not halt the rest of the process
            } fi
        } done
    } fi

    if command::exists apt; then {
        log::info "Installing ubuntu system packages";
        (
            sudo apt-get update;
            sudo debconf-set-selections <<<'debconf debconf/frontend select Noninteractive';
            for level in ${!aptpkgs_level_*}; do {
                declare -n ref="$level";
                if test -n "${ref:-}"; then {
                    sudo apt-get install -yq --no-install-recommends "${ref[@]}";
                } fi
            } done
            sudo debconf-set-selections <<<'debconf debconf/frontend select Readline';
        ) 1>/dev/null & disown;
    } fi


    log::info "Installing userland packages with nix";
    (
        # Install tools with nix
        USER="$(id -u -n)" && export USER;
        if test ! -e /nix; then {
            sudo sh -c "mkdir -p /nix && chown -R $USER:$USER /nix";
            log::info "Installing nix";
            curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon >/dev/null 2>&1;
        } fi
        source "$HOME/.nix-profile/etc/profile.d/nix.sh" 2>/dev/null || source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh;

        function nix-install() {
            if test ! -v nix_unstable_installed && [[ "$*" == *nixpkgs-unstable.* ]]; then {
                nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable;
                nix-channel --update;
                nix_unstable_installed=true;
            } fi
            command nix-env -iAP "$@" 2>&1 \
                | grep --line-buffered -vE '^(copying|building|generating|  /nix/store|these|this path will be fetched)';
        }

        for level in ${!nixpkgs_level_*}; do {
            declare -n ref="$level";
            if test -n "${ref:-}"; then {
                nix-install "${ref[@]}";
            } fi
        } done
    ) & disown;
}
