# =================================================
# = system packages                               =
# =================================================

# shellcheck disable=SC2034
# It is adviced to add very less packages in this array
# Things that you need immediately should be added here
syspkgs_level_one=(
    tmux
    fish
    jq
)

# shellcheck disable=SC2034
syspkgs_level_two=(
    # Add big packages in this array
)

# =================================================
# = userland packages                             =
# =================================================

## You can find packages at https://search.nixos.org/packages
# It is adviced to add very less packages in this array
# Things that you need immediately should be added here
userpkgs_level_one=(
    tmux
    fish
    jq
)
# Empty userpkgs_level_one when the system is ubuntu and cde
### And so, install from [syspkgs_level_one] instead
if std::sys::info::distro::is_ubuntu && is::cde; then {
    userpkgs_level_one=(); 
} fi

# shellcheck disable=SC2034
userpkgs_level_two=(
    lsof
    shellcheck
    # rsync
    tree
    file
    fzf
    # bash
    bat
    bottom
    # coreutils
    exa
    # ffmpeg
    # fish
    fzf
    # gawk
    gh
    # htop
    # iftop
    # jq
    neofetch
    neovim
    p7zip
    # ranger
    # reattach-to-user-namespace
    ripgrep
    shellcheck
    tree
    # yq
    jq
    zoxide
    rclone
    # zsh
)

function install::packages {

    # return # DEBUG
    log::info "Installing system packages";
    (
        sudo apt-get update;
        sudo debconf-set-selections <<<'debconf debconf/frontend select Noninteractive';
        for level in syspkgs_level_one syspkgs_level_two; do {
            declare -n ref="$level";
            if test -n "${ref:-}"; then {
                sudo apt-get install -yq --no-install-recommends "${ref[@]}";
            } fi
        } done
        sudo debconf-set-selections <<<'debconf debconf/frontend select Readline';
    ) 1>/dev/null & disown;

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

        # return # DEBUG
        for level in userpkgs_level_one userpkgs_level_two; do {
            declare -n ref="$level";
            if test -n "${ref:-}"; then {
                nix-env -f channel:nixpkgs-unstable -iA "${ref[@]}" >/dev/null 2>&1;
            } fi
        } done
    ) & disown;
}
