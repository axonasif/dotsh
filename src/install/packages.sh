function install::packages {
    # shellcheck disable=SC2034

    # =================================================
    # = assign dynamic packages                       =
    # =================================================
    nixpkgs_level_one+=(nixpkgs."${DOTFILES_SHELL:-fish}")

    case "${DOTFILES_EDITOR:-neovim}" in
        "emacs")
            : "nixpkgs.emacs";
        ;;
        "helix")
            : "nixpkgs.helix";
        ;;
        "neovim")
            : "nixpkgs-unstable.neovim";
        ;;
    esac
    nixpkgs_level_two+=("$_")

    if ! command -v git 1>/dev/null; then {
        nixpkgs_level_two+=(nixpkgs.git);
    } fi
    if [[ "${GITPOD_WORKSPACE_CONTEXT_URL:-}" == *gitlab* ]] \
    && ! [[ "${GITPOD_WORKSPACE_CONTEXT_URL:-}" == *github.com/* ]]; then {
        nixpkgs_level_two+=(nixpkgs.glab);
    } else {
        nixpkgs_level_two+=(nixpkgs.gh);
    } fi

    if os::is_darwin; then {

        # Install brew if missing
        if test ! -e /opt/homebrew/Library/Taps/homebrew/homebrew-core/.git \
        && test ! -e /usr/local/Library/Taps/homebrew/homebrew-core/.git; then {
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
        } fi

        log::info "Installing userland packages with brew";
        if ! command -v brew 1>/dev/null; then {
            PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"; # Intentionally low-prio
            eval "$(brew shellenv)";
        } fi
        NONINTERACTIVE=1 brew install -q "${brewpkgs_level_one[@]}" || true; # Do not halt the rest of the process
    } fi

    if distro::is_ubuntu; then {
        log::info "Installing ubuntu system packages";
        (
            sudo apt-get update;
            sudo debconf-set-selections <<<'debconf debconf/frontend select Noninteractive';
            for level in aptpkgs; do {
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
            command nix-env -iAP "$@" 2>&1 \
                | grep --line-buffered -vE '^(copying|building|generating|  /nix/store|these)';
        }

        if test -n "${nixpkgs_level_one:-}"; then {
            nix-install "${nixpkgs_level_one[@]}";
        } fi

        nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable;
        nix-channel --update;
        if test -n "${nixpkgs_level_two:-}"; then {
            nix-install "${nixpkgs_level_two[@]}";
        } fi

        if test -n "${nixpkgs_level_three:-}"; then {
            nix-install "${nixpkgs_level_three[@]}";
        } fi
    ) & disown;
}
