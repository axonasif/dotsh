
# shellcheck disable=SC2034

if test -e "/nix"; then {
    # =================================================
    # = userland packages                             =
    # =================================================

    ## Install from nix when it's immediately available,
    ## otherwise fallback to apt for faster response.
    ## You can find packages at https://search.nixos.org/packages

    # It is adviced to add very less packages in this array.
    # Things that you need immediately should be added here.
    nixpkgs_level_one=(
        nixpkgs.tmux
        nixpkgs.fish
        nixpkgs.jq
    )

    # Big packages here.
    nixpkgs_level_two=(
        nixpkgs.rclone
        nixpkgs.zoxide
        nixpkgs.git
        nixpkgs-unstable.neovim
        nixpkgs.gnumake
        nixpkgs.shellcheck
        nixpkgs.tree
        nixpkgs.file
        nixpkgs.fzf
        nixpkgs.bat
        nixpkgs.bottom
        nixpkgs.coreutils
        nixpkgs.exa
        nixpkgs.fzf
        nixpkgs.gawk
        nixpkgs.gh
        nixpkgs.htop
        nixpkgs.lsof
        # iftop
        nixpkgs.neofetch
        nixpkgs.p7zip
        nixpkgs.ripgrep
        nixpkgs.shellcheck
        nixpkgs.tree
        # yq
    )

    # Packages specific to MacOS
    if os::is_darwin; then {
        # Add to array
        nixpkgs_level_two+=(
            nixpkgs.bash
            nixpkgs.zsh
            nixpkgs.reattach-to-user-namespace
        )
    } fi

} elif is::cde && distro::is_ubuntu; then {
    # =================================================
    # = system packages                               =
    # =================================================

    # It is adviced to add very less packages in this array.
    # Things that you need immediately should be added here.
    aptpkgs_level_one=(
        tmux
        fish
        jq
    )

    # Big packages here.
    aptpkgs_level_two=(
        fuse
        git
        make
    )
} fi

function install::packages {

    # Only install from APT when it's CDE and Ubuntu
    if is::cde && distro::is_ubuntu; then {
        log::info "Installing system packages";
        (
            sudo apt-get update;
            sudo debconf-set-selections <<<'debconf debconf/frontend select Noninteractive';
            for level in aptpkgs_level_one aptpkgs_level_two; do {
                declare -n ref="$level";
                if test -n "${ref:-}"; then {
                    sudo apt-get install -yq --no-install-recommends "${ref[@]}";
                } fi
            } done
            sudo debconf-set-selections <<<'debconf debconf/frontend select Readline';
        ) 1>/dev/null & disown;
    } fi

    log::info "Installing userland packages";
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
        } 1>/dev/null

        if test -n "${nixpkgs_level_one:-}"; then {
            nix-install "${nixpkgs_level_one[@]}";
        } fi

        nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable;
        nix-channel --update;
        if test -n "${nixpkgs_level_two:-}"; then {
            nix-install "${nixpkgs_level_two[@]}";
        } fi

    ) & disown;
}
