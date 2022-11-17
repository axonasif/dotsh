use bash;
use fish;
use zsh;

function config::shell {
	# TODO: Propose fix to upstream
	sed -i '/ set +o history/,/truncate -s 0 "$HISTFILE"/d' "/ide/startup.sh" 2>/dev/null || :;

	case "${DEFAULT_SHELL:-fish}" in
		"bash")
			config::shell::bash & disown;
		;;
		"fish")
			config::shell::fish & disown;
			config::shell::fish::append_hist_from_gitpod_tasks & disown;
		;;
		"zsh")
			config::shell::zsh & disown;
		;;
	esac

	config::shell::set_default_vscode_profile & wait;
}

function config::shell::set_default_vscode_profile() {
	log::info "Setting the integrated tmux shell for VScode as default";
	local pyh="$HOME/.bashrc.d/60-python"
	if test -e "$pyh"; then {
		# TODO: Propose fix to upstream
		sed -i '/local lockfile=.*/,/touch "$lockfile"/c mkdir /tmp/.vcs_add.lock || exit 0' "$pyh";
	} fi
	local json_data;

	json_data="$(
		if [ "${DOTFILES_TMUX:-true}" == true ] && [ "${DOTFILES_TMUX_VSCODE:-true}" == true ]; then {
			cat <<-'JSON' | sed "s|main|${tmux_first_session_name}|g"
			{
				"terminal.integrated.profiles.linux": {
					"tmuxshell": {
						"path": "bash",
						"args": [
							"-c",
							"until cmd=\"$(command -v tmux)\" && test -x \"$cmd\"; do sleep 1; done; AWAIT_SHIM_PRINT_INDICATOR=true tmux new-session -ds main 2>/dev/null || :; if cpids=$(tmux list-clients -t main -F '#{client_pid}'); then for cpid in $cpids; do [ $(ps -o ppid= -p $cpid)x = ${PPID}x ] && exec tmux new-window -n \"vs:${PWD##*/}\" -t main; done; fi; exec tmux attach -t main;"
						]
					}
				},
				"terminal.integrated.defaultProfile.linux": "tmuxshell"
			}
			JSON
		} else {
			shell="$(get::default_shell)" && shell="${shell##*/}";
			cat <<-JSON
			{
				"terminal.integrated.defaultProfile.linux": "$shell"
			}
			JSON
		} fi
	)"

	# TIME=2 await::for_file_existence "$ms_vscode_server_dir";
	vscode::add_settings \
		"$vscode_machine_settings_file" \
		"$HOME/.vscode-server/data/Machine/settings.json" \
		"$HOME/.vscode-remote/data/Machine/settings.json" <<<"$json_data"

}