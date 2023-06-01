use bash;
use fish;
use zsh;

function config::shell {
	# TODO: Propose fix to upstream
	sed -i '/ set +o history/,/truncate -s 0 "$HISTFILE"/d' "/ide/startup.sh" 2>/dev/null || :;

	(
		await::signal get install_dotfiles;
		case "${DOTFILES_SHELL:-fish}" in
			"bash")
				config::shell::bash;
			;;
			"fish")
				config::shell::fish;
				config::shell::fish::append_hist_from_gitpod_tasks;
			;;
			"zsh")
				config::shell::zsh;
			;;
		esac

	) & disown;

	config::shell::set_default_vscode_profile &

	if is::gitpod; then {
		if test "${DOTFILES_SPAWN_SSH_PROTO:-true}" == true; then {
			config::shell::spawn_ssh_url & disown;
		} fi

		config::shell::hijack_gitpod_task_terminals;
		if test -e /ide/xterm; then {
			config::shell::hijack_xtermjs;
		} fi
	} fi

	if jobs="$(jobs -rp)" && test -n "${jobs:-}"; then {
		wait $jobs;
	} fi
}

function config::shell::hijack_gitpod_task_terminals {
	function tmux::inject() {
		# The supervisor creates the task terminals, supervisor calls BASH from `/bin/bash` instead of the realpath `/usr/bin/bash`
		if [ "$BASH" == /bin/bash ] || [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ]; then {
			if test -v TMUX; then {
				return;
			} fi

			if test "${DOTFILES_TMUX:-true}" == true; then {

				# Switch to tmux on SSH.
				if test -v SSH_CONNECTION; then {
					if test "${DOTFILES_NO_VSCODE:-false}" == "true"; then {
						pkill -9 vimpod || :;
					} fi
					# Tmux window sizing conflicts happen as by default it inherits the smallest client sizes (which is usually the terminal TAB on VSCode)
					# There are two things we can do, either detach all the connected clients. (tmux detach -t main)
					# or tell tmux to allways use the largest size, which can confuse some people sometimes.
					# I'll go with the second option for now
					# (for i in {1..5}; do sleep 2 && tmux set-window-option -g -t main window-size largest; done) & disown
					AWAIT_SHIM_PRINT_INDICATOR=true tmux_create_session;
					exec tmux set -g -t "${tmux_first_session_name}" window-size largest\; attach \; attach -t :${tmux_first_window_num};
				} else {
					local stdin;
					IFS= read -t0.01 -u0 -r -d '' stdin || :;
					if test -n "${stdin:-}"; then {
						if ! grep -q "^$dotfiles_notmux_sig\$" <<<"$stdin"; then {
							# Terminate gitpod created task terminals so that we can take over,
							# previously this was done in a more complicated way via `tmux_old.sh:tmux::inject_old_complicated()` :P
							exit 0;
						} else {
							cmd="$(get::task_cmd "$stdin")";
							exec bash -lic "$cmd";
						} fi
					} fi
				} fi

			} else {

				local stdin cmd;
				IFS= read -t0.01 -u0 -r -d '' stdin || :;

				if test -n "$stdin"; then {
					cmd="$(get::task_cmd "$stdin")";
					exec bash -lic "$cmd";
				} fi

			} fi

	  exit;
		} fi
	}
	# For debugging
	# trap 'read -p eval: && eval "$REPLY"' ERR EXIT SIGTERM SIGINT
	
	# Make gitpod task spawned terminals use fish
	if ! grep -q 'PROMPT_COMMAND=".*tmux::inject.*"' "$HOME/.bashrc" 2>/dev/null; then {
		# log::info "Setting tmux as the interactive shell for Gitpod task terminals"
		local function_exports=(
	  tmux::new-session
			tmux_create_session
			tmux::inject
			get::task_cmd
	  tmux::show-option
			get::default_shell
			await::signal
		)
		# Entry point, very important!!!
		{
			printf '%s="%s"\n' tmux_first_session_name "$tmux_first_session_name" \
								tmux_first_window_num "$tmux_first_window_num" \
								dotfiles_notmux_sig "$dotfiles_notmux_sig" \
								PROMPT_COMMAND 'tmux::inject; $PROMPT_COMMAND' \
				RC "$RC" \
				BGREEN "$BGREEN" \
				BRED "$BRED" \
				YELLOW "$YELLOW";

			printf '%s="${%s:-%s}"\n' DOTFILES_TMUX DOTFILES_TMUX "${DOTFILES_TMUX:-true}" \
										DOTFILES_TMUX_NO_VSCODE DOTFILES_TMUX_NO_VSCODE "${DOTFILES_TMUX_NO_VSCODE:-false}" \
										DOTFILES_SHELL "${DOTFILES_SHELL:-fish}";

			printf '%s\n' "$(declare -f "${function_exports[@]}")";
		} >> "$HOME/.bashrc";
	} fi
}

function config::shell::spawn_ssh_url() {
	if ! (set -o noclobber && printf '' > /tmp/.dotsh_spawn_ssh) 2>/dev/null; then {
		return;
	} fi

	"$___self_DIR/src/utils/vimpod.py" & disown;
	(
		{ gp ports await 23000 && gp ports await 22000; } 1>/dev/null && gp preview "$(gp url 22000)" --external && {
			if test "${DOTFILES_NO_VSCODE:-false}" == "true"; then {
				printf '%s\n' '#!/usr/bin/env sh' \
								'while sleep $(( 60 * 60 )); do continue; done' > /ide/bin/gitpod-code
				pkill -9 -f 'sh /ide/bin/gitpod-code';
			} fi
		}
	) & disown
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
				"terminal.integrated.profiles.linux": {
					"customshell": {
						"path": "bash",
						"args": [
							"-c",
							"until cmd=\"\$(command -v $shell)\" && test -x \"\$cmd\"; do sleep 1; done; AWAIT_SHIM_PRINT_INDICATOR=true exec \$cmd -l"
						]
					}
				},
				"terminal.integrated.defaultProfile.linux": "customshell"
			}
			JSON
		} fi
	)"

	# TIME=2 await::for_file_existence "$ms_vscode_server_dir";
	function perform() {
		vscode::add_settings \
			"$vscode_machine_settings_file" \
			"$HOME/.vscode-server/data/Machine/settings.json" \
			"$HOME/.vscode-remote/data/Machine/settings.json" <<<"$json_data"
	}

	perform;
	for _ in {1..3}; do perform; sleep 3.5; done & disown;
}

function config::shell::hijack_xtermjs() {
	function inject() {
		if [ "$PPID" == "$(pgrep -f '/ide/xterm/bin/node /ide/xterm/index.cjs' | head -n1)" ] && test ! -v TMUX; then {
			if test "${DOTFILES_TMUX:-true}" == true; then {
				printf 'Loading %s ...\n' tmux;
				AWAIT_SHIM_PRINT_INDICATOR=true tmux_create_session;
				exec tmux set -g -t "${tmux_first_session_name}" window-size largest\; attach \; attach -t :${tmux_first_window_num};
			} else {
				exec "${DOTFILES_SHELL:-fish}";
			} fi
		} fi
	}

	payload=$(declare -f inject);
	payload="${payload#*{}";
	payload="${payload%\}}";
	
	printf '%s\n' "${payload}" >> "$HOME/.bashrc";
}