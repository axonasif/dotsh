# shellcheck disable=SC2034

# UPPERCASE variables may be supplied as environment variables instead.

# Add nix bin PATH in advance
export PATH="$PATH:$HOME/.nix-profile/bin";


# =================================================
# = DOTFILES REPO TREES                           =
# =================================================
# As many dotfiles repo you want to install and merge together.
declare dotfiles_repos=(
    # Defaults to axonasif's repo, you may remove below line
    "${DOTFILES_PRIMARY_REPO:-https://github.com/axonasif/dotfiles.public}"
)


# =================================================
# = SHELL                                         =
# =================================================
# Defaults to fish
: "${DOTFILES_SHELL:=fish}";
# =================================================
# = FISH SHEL                                     =
# =================================================
declare -r fish_confd_dir="$HOME/.config/fish/conf.d";
declare -r fish_hist_file="$HOME/.local/share/fish/fish_history";
declare fish_plugins+=(
    PatrickF1/fzf.fish
    jorgebucaran/fisher
)


# =================================================
# = TMUX OPTIONS                                  =
# =================================================
# Tmux is enabled by default.
: "${DOTFILES_TMUX:=true}"
# TODO: DOTFILES_TMUX_VSCODE
declare -r tmux_first_session_name="main";
declare -r tmux_first_window_num="1";


# =================================================
# = MISCELLANEOUS OPTIONS                         =
# =================================================
# The below option will help you easily SSH into
# your workspace via your local terminal emulator.
: "${DOTFILES_SPAWN_SSH_PROTO:=true}";
# When the below option is true, VSCode will be
# killed after you've established a SSH connection
# with the workspace.
: "${DOTFILES_NO_VSCODE:=false}"; #


# =================================================
# = EDITOR                                        =
# =================================================
# Defaults to neovim
# Supported value(s): emacs, helix, neovim
: "${DOTFILES_EDITOR:=neovim}";
# =================================================
# = EDITOR PRESET                                 =
# =================================================
# Defaults to lunarvim (editor dependant)
# Supported value(s): lunarvim, nvchad, doomemacs, spacemacs
# You may not use any preset when you have your own config
# You should use a preset based on your EDITOR
: "${DOTFILES_EDITOR_PRESET:=lunarvim}";


# =================================================
# = PACKAGES                                      =
# =================================================
# Packages are chunked into different levels to optimize terminal readiness.
# You can find packages at https://search.nixos.org/packages
# =================================================
# = IMMIDIATE PACKAGES                            =
# =================================================
# It is adviced to add very less packages in this array.
# Things that you need immediately should be added here.
# Your DOTFILES_SHELL is internally included.
declare nixpkgs_level_one+=(
    nixpkgs.tmux
    nixpkgs.jq
)
# =================================================
# = SEMI-BIG PACKAGES                             =
# =================================================
# Mostly shell dependencies.
# Your DOTFILES_EDITOR is internally included.
# gh/glab CLI is internally included based on git context.
declare nixpkgs_level_two+=(
    nixpkgs.rclone
    nixpkgs.zoxide
    nixpkgs.bat
    nixpkgs.fzf
    nixpkgs.exa
)
# =================================================
# = BIG PACKAGES                                  =
# =================================================
declare nixpkgs_level_three+=(
    nixpkgs.gnumake
    nixpkgs.gcc
    nixpkgs.shellcheck
    nixpkgs.file
    nixpkgs.fd
    nixpkgs.bottom
    nixpkgs.coreutils
    nixpkgs.htop
    nixpkgs.lsof
    nixpkgs.neofetch
    nixpkgs.p7zip
    nixpkgs.ripgrep
    nixpkgs.rsync
    # nixpkgs.yq
)
# =================================================
# = EXTRA MACOS-SPECIFIC PACKAGES                 =
# =================================================
if os::is_darwin; then {
    # Additional nix packages
    nixpkgs_level_three+=(
        nixpkgs.gawk
        nixpkgs.bashInteractive # macos still stuck with old bash... so...
        nixpkgs.reattach-to-user-namespace
    )
    
    # Brew packages
    declare brewpkgs_level_one+=(
        osxfuse
    )
} fi
# =================================================
# = UBUNTU/DEBIAN SYSTEM PACKAGES                 =
# =================================================
declare aptpkgs+=(
    fuse
)


# Gitpod specific
declare -r workspace_dir="$(
    if is::gitpod; then {
        printf '%s\n' "/workspace";
    } elif is::codespaces; then {
        printf '%s\n' "/workspaces";
    } fi
)";
declare -r workspace_persist_dir="$workspace_dir/.persist_root";
declare -r vscode_machine_settings_file="$(
    if is::gitpod; then {
        : "$workspace_dir";
    } else {
        : "$HOME";
    } fi
    printf '%s\n' "$_/.vscode-remote/data/Machine/settings.json";
)";


# Dotfiles specific
#declare -r dotfiles_sh_home="$HOME/.dotfiles-sh";
declare -r dotfiles_sh_repos_dir="$___self_DIR/repos";

# Rclone specific
declare -r rclone_mount_dir="$HOME/cloudsync";
declare -r rclone_conf_file="$HOME/.config/rclone/rclone.conf";
declare -r rclone_profile_name="cloudsync";
declare rclone_cmd_args=(
    --config="$rclone_conf_file"
    mount
    --allow-other
    --async-read
    --vfs-cache-mode=full
    "${rclone_profile_name}:" "$rclone_mount_dir"
)
declare files_to_persist_locally=(
    "${HISTFILE:-"$HOME/.bash_history"}"
    "${HISTFILE:-"$HOME/.zsh_history"}"
    "$fish_hist_file"
)