# shellcheck disable=SC2034

# UPPERCASE variables may be supplied as environment variables instead.
# That means you can define them at https://gitpod.io/variables with */* scope.

# Add nix, .local and ide bindir to PATH in advance
export PATH="$PATH:$HOME/.local/bin:/ide/bin/remote-cli:$HOME/.nix-profile/bin";


# =================================================
# = DOTFILES REPO TREES                           =
# =================================================
# As many dotfiles repo you want to install together.
declare dotfiles_repos=(
    # Defaults to an example template repo, you may remove below line and put your own or not use any at all!
    # If you do not have your own repo yet, you can fork this one as the starting point ;)
    https://github.com/axonasif/dotfiles.public
)
# Overwrite if the DOTFILES_REPOS environment variable is set
if test -n "${DOTFILES_REPOS:-}"; then {
    dotfiles_repos=(${DOTFILES_REPOS});
} fi


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
    axonasif/bashenv.fish
)


# =================================================
# = TMUX OPTIONS                                  =
# =================================================
# Tmux is enabled by default.
: "${DOTFILES_TMUX:=true}";
# Tmux integration for VSCode
: "${DOTFILES_TMUX_VSCODE:=true}";
declare -r tmux_first_session_name="gitpod";
declare -r tmux_first_window_num="1";


# =================================================
# = MISCELLANEOUS OPTIONS                         =
# =================================================
# The below option will help you easily SSH into
# your workspace via your local terminal emulator.
: "${DOTFILES_SPAWN_SSH_PROTO:=true}";
# When the below option is true, VSCode will be
# killed after you've established a SSH connection
# with the workspace to save RAM and CPU.
: "${DOTFILES_NO_VSCODE:=false}";


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
# You may not use any preset when you have your own config.
# Preset should be based on your EDITOR.
: "${DOTFILES_EDITOR_PRESET:=lunarvim}";


# =================================================
# = PACKAGES                                      =
# =================================================
# Packages are chunked into different levels to
# optimize terminal readiness, you can have as many levels you want.
# You can find packages at https://search.nixos.org/packages
# =================================================
# = IMMIDIATE PACKAGES                            =
# =================================================
# It is adviced to add very less packages in this array.
# Things that you need ASAP should be added here.
# DOTFILES_TMUX and DOTFILES_SHELL are internally included.
declare nixpkgs_level_1+=(
    nixpkgs.ripgrep
    nixpkgs.fd
    nixpkgs.fzf
)
# =================================================
# = SEMI-BIG PACKAGES                             =
# =================================================
# Mostly shell dependencies.
# Your DOTFILES_EDITOR is internally included.
# gh/glab CLI is internally included based on git context.
declare nixpkgs_level_2+=(
    nixpkgs.zoxide
    nixpkgs.rclone
    nixpkgs.bat
    nixpkgs.exa
)
# =================================================
# = BIG PACKAGES                                  =
# =================================================
# yq is included internally
declare nixpkgs_level_3+=(
    nixpkgs.shellcheck
    nixpkgs.file
    nixpkgs.bottom
    nixpkgs.coreutils
    nixpkgs.htop
    nixpkgs.lsof
    nixpkgs.neofetch
    nixpkgs.p7zip
    nixpkgs.rsync # Useful for 'bashbox livetest' command
    nixpkgs.helm
    nixpkgs.kubectl
    nixpkgs.k9s
    nixpkgs.google-cloud-sdk
    nixpkgs.doppler
)
if command::exists apt; then {
    aptpkgs_level_1+=(
        build-essential
        make
        gcc
    )
} else {
    nixpkgs_level_3+=(
        nixpkgs.gnumake
        nixpkgs.gcc
    )
} fi
# =================================================
# = EXTRA MACOS-SPECIFIC PACKAGES                 =
# =================================================
if os::is_darwin; then {
    # Additional nix packages
    nixpkgs_level_3+=(
        nixpkgs.gawk
        nixpkgs.bashInteractive # macos still stuck with old bash... so...
        nixpkgs.reattach-to-user-namespace
    )
    
    # Brew packages
    declare brewpkgs_level_1+=(
        osxfuse
    )
} fi
# =================================================
# = UBUNTU/DEBIAN SYSTEM PACKAGES                 =
# =================================================
declare aptpkgs_level_1+=(
    fuse
)


# =================================================
# = ADVANCED STUFF BELOW                          =
# =================================================

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
declare -r gitpod_scm_cli="$(
	if [[ "${GITPOD_WORKSPACE_CONTEXT_URL:-}" == *gitlab* ]] \
    && ! [[ "${GITPOD_WORKSPACE_CONTEXT_URL:-}" == *github.com/* ]]; then {
		: "glab";
    } else {
		: "gh";
    } fi
	printf '%s\n' "$_";
)";

# Dotfiles specific
#declare -r dotfiles_sh_home="$HOME/.dotfiles-sh";
declare -r dotfiles_sh_repos_dir="$___self_DIR/repos";
declare dotfiles_notmux_sig='# DOTFILES_TMUX_NO_TAKEOVER';

# Rclone specific
declare -r rclone_gitpod_env_var_name='DOTFILES_RCLONE_DATA';
declare -r rclone_mount_dir="$HOME/cloudsync";
declare -r rclone_conf_file="$HOME/.config/rclone/rclone.conf";
declare -r rclone_profile_name="cloudsync";
declare rclone_cmd_args=(
    --config="$rclone_conf_file"
    mount
    --daemon
    --allow-other
    --async-read
    --vfs-cache-mode=full
    "${rclone_profile_name}:" "$rclone_mount_dir"
)
declare rclone_dotfiles_sh_dir="$rclone_mount_dir/.dotfiles-sh";
declare rclone_dotfiles_sh_sync_dir="$rclone_dotfiles_sh_dir/sync";
declare rclone_dotfiles_sh_sync_relative_home_dir="$rclone_dotfiles_sh_sync_dir/relhome";
declare rclone_dotfiles_sh_sync_rootfs_dir="$rclone_dotfiles_sh_sync_dir/rootfs";
declare files_to_persist_locally=(
    "${HISTFILE:-"$HOME/.bash_history"}"
    "${HISTFILE:-"$HOME/.zsh_history"}"
    "$fish_hist_file"
)
