## Readonly variables

# Add nix bin PATH in advance
export PATH="$PATH:$HOME/.nix-profile/bin";

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

# Tmux specific
declare -r tmux_first_session_name="main";
declare -r tmux_first_window_num="1";

# Fish specific
declare -r fish_confd_dir="$HOME/.config/fish/conf.d";
declare -r fish_hist_file="$HOME/.local/share/fish/fish_history";

# Dotfiles specific
declare -r dotfiles_sh_home="$HOME/.dotfiles-sh";
declare -r dotfiles_sh_repos_dir="$dotfiles_sh_home/repos";

# Rclone specific
declare -r rclone_mount_dir="$HOME/cloudsync";
declare -r rclone_conf_file="$HOME/.config/rclone/rclone.conf";
declare -r rclone_profile_name="cloudsync";
