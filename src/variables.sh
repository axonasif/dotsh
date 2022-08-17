# Readonly variables
declare -r workspace_dir="/workspace";
declare -r vscode_machine_settings_file="/workspace/.vscode-remote/data/Machine/settings.json";
local source_dir="$(readlink -f "$0")" && declare -r source_dir="${source_dir%/*}"; # Full path to this repository directory.
