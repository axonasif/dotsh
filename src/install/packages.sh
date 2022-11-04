
function install::packages {
    # shellcheck disable=SC2034
    declare shell="${DOTFILES_DEFAULT_SHELL:-fish}";

    # =================================================
    # = userland packages                             =
    # =================================================

    # You can find packages at https://search.nixos.org/packages
    # It is adviced to add very less packages in this array.
    # Things that you need immediately should be added here.
    declare nixpkgs_level_one+=(
        nixpkgs.tmux
        "nixpkgs.${shell##*/}"
        nixpkgs.jq
    )

    # Semi-big packages here. Mostly shell dependencies
    declare nixpkgs_level_two+=(
        nixpkgs-unstable.neovim
        nixpkgs.rclone
        nixpkgs.zoxide
        nixpkgs.git
        nixpkgs.bat
        nixpkgs.fzf
        nixpkgs.exa
        nixpkgs.gh
    )
    
    # Big packages here
    declare nixpkgs_level_three+=(
        nixpkgs.gnumake
        nixpkgs.gcc
        nixpkgs.shellcheck
        nixpkgs.file
        nixpkgs.bottom
        nixpkgs.coreutils
        nixpkgs.gawk
        nixpkgs.htop
        nixpkgs.lsof
        nixpkgs.neofetch
        nixpkgs.p7zip
        nixpkgs.ripgrep
        nixpkgs.tree
        # nixpkgs.yq
    )

    if os::is_darwin; then {
        # =================================================
        # = macos specific brew packages                  =
        # =================================================
        declare brewpkgs_level_one+=(
            bash # macos still stuck with old bash... so...
            osxfuse
            reattach-to-user-namespace
        )

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
        NONINTERACTIVE=1 brew install -q "${brewpkgs_level_one[@]}";
    } fi

    if distro::is_ubuntu; then {
        # =================================================
        # = ubuntu system packages                        =
        # =================================================
        declare aptpkgs+=(
            fuse
        )

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
        source "$HOME/.nix-profile/etc/profile.d/nix.sh" || source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh;

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
