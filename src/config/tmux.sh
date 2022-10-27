use std::term::colors;

function tmux::create_session() {
	tmux new-session -c "${GITPOD_REPO_ROOT:-$HOME}" -n editor -ds "${tmux_first_session_name}" 2>/dev/null || :;
	#\; send-keys -t :${tmux_first_window_num} "cat $HOME/.dotfiles.log" Enter 
	tmux_default_shell="$(tmux display -p '#{default-shell}')";
}

function tmux::create_window() {
	tmux new-window -n "${WINDOW_NAME:-vs:${PWD##*/}}" -t "$tmux_first_session_name" "$@";
}

function tmux::start_vimpod() {
	local lockfile=/tmp/.vimpod;
	if test -e "$lockfile"; then return 0; fi
	touch "$lockfile"
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

function inject_tmux() {
	# The supervisor creates the task terminals, supervisor calls BASH from `/bin/bash` instead of the realpath `/usr/bin/bash`
	if [ "$BASH" == /bin/bash ] || [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ]; then {
		if test -v TMUX; then {
			return;
		} fi

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
			tmux::create_session;
			exec tmux set-window-option -g -t "${tmux_first_session_name}" window-size largest\; attach \; attach -t :${tmux_first_window_num};
		} else {
			exit 0; # Terminate gitpod created task terminals so that we can take over, previously this was done in a more complicated way via `tmux_old.sh:inject_tmux_old_complicated()` :P
		} fi

	} fi
}

function config::tmux::hijack_gitpod_task_terminals {
	# For debugging
	# trap 'read -p eval: && eval "$REPLY"' ERR EXIT SIGTERM SIGINT
	
	# Make gitpod task spawned terminals use fish
	if ! grep -q 'PROMPT_COMMAND=".*inject_tmux.*"' "$HOME/.bashrc" 2>/dev/null; then {
	log::info "Setting tmux as the interactive shell for Gitpod task terminals"

		# Entry point, very important!!!
		printf '%s\n' "tmux_first_session_name=$tmux_first_session_name" \
						"tmux_first_window_num=$tmux_first_window_num" \
						"tmux_init_lock=$tmux_init_lock" \
						"$(declare -f tmux::start_vimpod tmux::create_session inject_tmux)" \
						'PROMPT_COMMAND="inject_tmux;$PROMPT_COMMAND"' >> "$HOME/.bashrc";
	} fi
}

function config::tmux::set_tmux_as_default_vscode_shell() {
	log::info "Setting the integrated tmux shell for VScode as default";
	local json_data;
	json_data="$(cat <<-'JSON' | sed "s|main|${tmux_first_session_name}|g"
		{
			"terminal.integrated.profiles.linux": {
				"tmuxshell": {
					"path": "bash",
					"args": [
						"-c",
						"set -x && exec 2>>/tmp/.tvlog; until command -v tmux 1>/dev/null; do sleep 1; done; tmux new-session -ds main 2>/dev/null || :; if cpids=$(tmux list-clients -t main -F '#{client_pid}'); then for cpid in $cpids; do [ $(ps -o ppid= -p $cpid)x == ${PPID}x ] && exec tmux new-window -n \"vs:${PWD##*/}\" -t main; done; fi; exec tmux attach -t main; "
					]
				}
			},
			"terminal.integrated.defaultProfile.linux": "tmuxshell"
		}
	JSON
	)"

	printf '%s\n' "$json_data" | vscode::add_settings;
	# For vscode desktop
	# TIME=2 await::for_file_existence "$ms_vscode_server_dir";
	local dir;
	for dir in '.vscode-server' '.vscode-remote'; do {
		printf '%s\n' "$json_data" | SETTINGS_TARGET="$HOME/$dir/data/Machine/settings.json" vscode::add_settings;
	} done
}

function config::tmux() {
	# Lock on tmux
	local tmux_exec_path="/usr/bin/tmux";
	log::info "Setting up tmux";
	if is::cde; then {
		KEEP="true" await::create_shim "$tmux_exec_path";
	} else {
		await::until_true command -v tmux 1>/dev/null;
	} fi

	{
		# Extra steps
		if is::cde; then {
			config::tmux::set_tmux_as_default_vscode_shell & disown;
		} fi
		
		if is::gitpod; then {
			if test "${DOTFILES_SPAWN_SSH_PROTO:-true}" == true; then {
				tmux::start_vimpod & disown;
			} fi
			config::tmux::hijack_gitpod_task_terminals &
		} fi


		local target="$HOME/.tmux/plugins/tpm";
		if test ! -e "$target"; then {
			git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target" >/dev/null 2>&1;
			await::signal get install_dotfiles;
			bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" || :
		} fi

		if is::cde; then {
			local tmux_default_shell;
			tmux::create_session;
		} fi

		(
			if is::gitpod; then {
				if test -n "${GITPOD_TASKS:-}"; then {
					log::info "Spawning Gitpod tasks in tmux";
				} else {
					return;
				} fi

				await::for_file_existence "$workspace_dir/.gitpod/ready";
				if ! cd "${GITPOD_REPO_ROOT:-}"; then {
					log::error "Can't cd into ${GITPOD_REPO_ROOT:-}" 1 || exit;
				} fi

				function jqw() {
					local cmd;
					if cmd=$(jq -er "$@" <<<"$GITPOD_TASKS") 2>/dev/null; then {
						printf '%s\n' "$cmd";
					} else {
						return 1;
					} fi
				}

				local name cmd arr_elem=0;
				until {
					! cmd_prebuild="$(jqw ".[${arr_elem}] | [.init] | map(select(. != null)) | .[]")" && \
					! cmd_others="$(jqw ".[${arr_elem}] | [.before, .command] | map(select(. != null)) | .[]")"
				}; do {
					if ! name="$(jqw ".[${arr_elem}].name")"; then {
						name="AnonTask-${arr_elem}";
					} fi

					local prebuild_log="$workspace_dir/.gitpod/prebuild-log-${arr_elem}";
					
					cmd="$(
						task="$(
							if test -e "$prebuild_log"; then {
								printf 'cat %s\n' "$prebuild_log";
								printf '%s\n' "${cmd_others:-}";
							} else {
								printf '%s\n' "${cmd_prebuild:-}" "${cmd_others:-}";
							} fi
						)"
IFS='' read -rd '' cmdc <<CMDC || :;
trap "exec /usr/bin/fish -l" EXIT
printf "$BGREEN>> Executing task:$RC\n";
IFS='' read -rd '' lines <<'EOF' || :;
$task
EOF
printf '%s\n' "\$lines" | while IFS='' read -r line; do
	printf "    ${YELLOW}%s${RC}\n" "\$line";
done
printf '\n';
$task
CMDC
						printf '%s\n' "$cmdc";
					)";

					# win_i="$(
						# )";

					WINDOW_NAME="$name" tmux::create_window bash -cli "$cmd";
					# tmux send-keys -t "${tmux_first_session_name}:${win_i}" Enter "trap 'exec $tmux_default_shell -l' EXIT; cat /workspace/.gitpod/prebuild-log-${arr_elem} 2>/dev/null && exit; ${cmd%;}; exit";
					#bash -c " printf '%s\n' $cmd; $cmd;"
					((arr_elem=arr_elem+1));
				} done


			# Install gitpod specific ephemeral plugins
			## Dotfiles loading indicator (spinner)
			local spinner="/usr/bin/tmux-dotfiles-spinner.sh";
			local spinner_data="$(
				printf '%s\n' '#!/bin/bash' "$(declare -f sleep)";

				cat <<'EOF'
set -eu;
while pgrep -f "$HOME/.dotfiles/install.sh" 1>/dev/null; do
	for s in / - \\ \|; do
		sleep 0.1;
		printf '%s \n' "#[bg=#ff5555,fg=#282a36,bold] $s Dotfiles";
	done
done

current_status="$(tmux display -p '#{status-right}')";
tmux set -g status-right "$(printf '%s\n' "$current_status" | sed "s|#(exec $0)||g")"
EOF
			)"

			local resources_indicator="/usr/bin/tmux-resources-indicator.sh";
			local resources_indicator_data="$(
			printf '%s\n' '#!/bin/bash' "$(declare -f sleep)";

				cat <<'EOF'
printf '\n'; # init quick draw

while true; do {
	# Read all properties
	IFS=$'\n' read -d '' -r mem_used mem_max cpu_used cpu_max \
		< <(gp top -j | jq -r ".resources | [.memory.used, .memory.limit, .cpu.used, .cpu.limit] | .[]")

	# Human friendly memory numbers
	read -r hmem_used hmem_max < <(numfmt -z --to=iec --format="%8.2f" $mem_used $mem_max);

	# CPU percentage
	cpu_perc="$(( (cpu_used * 100) / cpu_max ))";

	# Print to tmux
	printf '%s\n' " #[bg=#ffb86c,fg=#282a36,bold] CPU: ${cpu_perc}% #[bg=#8be9fd,fg=#282a36,bold] MEM: ${hmem_used%?}/${hmem_max} ";
	sleep 3;
} done
EOF
			)"

			{
				printf '%s\n' "$spinner_data" | sudo tee "$spinner";
				printf '%s\n' "$resources_indicator_data" | sudo tee "$resources_indicator";
			} 1>/dev/null;
			sudo chmod +x "$spinner" "$resources_indicator";

			tmux set-option -g status-left-length 100\; set-option -g status-right-length 100\; \
				set-option -ga status-right "#(exec $resources_indicator)#(exec $spinner)";

			} elif is::codespaces && test -e "${CODESPACES_VSCODE_FOLDER:-}"; then {
				cd "$CODESPACE_VSCODE_FOLDER" || :;
			} fi
		) || :;

		CLOSE=true await::create_shim "$tmux_exec_path";
		await::signal send config_tmux;
	 } & disown;
}
