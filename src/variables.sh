# Add nix bin PATH in advance
export PATH="$PATH:$HOME/.nix-profile/bin";

# Readonly variables
declare -r workspace_dir="$(
	if is::gitpod; then {
		printf '%s\n' "/workspace";
	} elif is::codespaces; then {
		printf '%s\n' "/workspaces";
	} fi
)";
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
declare -r tmux_init_lock="/tmp/.tmux.init";

# Fish specific
declare -r fish_confd_dir="$HOME/.config/fish/conf.d" && mkdir -p "$fish_confd_dir";

