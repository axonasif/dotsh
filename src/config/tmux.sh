use std::term::colors;
use libtmux::session;
use libtmux::window;

declare dotfiles_notmux_sig='# DOTFILES_TMUX_NO_TAKEOVER';

function tmux_create_session() {
	SESSION_NAME="$tmux_first_session_name" \
  WINDOW_NAME="editor" \
    tmux::new-session -c "${GITPOD_REPO_ROOT:-$HOME}" \
      -- "$(get::default_shell)" -li 2>/dev/null || :;
}

function tmux_create_window() {
  SESSION_NAME="$tmux_first_session_name" tmux::new-window "$@";
}

# TODO: Decouple it from here
function tmux::start_vimpod() {
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

function get::task_cmd() {
	local task="$1";
	local cmdc;
	local cmdc_tmp_file="/tmp/.dotfiles_task_cmd.$((RANDOM * $$))";
	IFS='' read -rd '' cmdc <<CMDC || :;
function ___exit_callback() {
	local r=\$?;
	rm -f "$cmdc_tmp_file" 2>/dev/null || true;
	if test -z "\${___manual_exit:-}"; then {
		exec '$(get::default_shell)' -il;
	} else {
		printf "\n${BRED}>> This task issued manual 'exit' with return code \$r${RC}\n";
		printf "${BRED}>> Press Enter or Return to dismiss${RC}" && read -r -n 1;
	} fi
}
function exit() {
	___manual_exit=true;
	command exit "\$@";
}; export -f exit;
trap "___exit_callback" EXIT;
printf "$BGREEN>> Executing task in bash:$RC\n";
IFS='' read -rd '' lines <<'EOF' || :;
$task
EOF
printf '%s\n' "\$lines" | while IFS='' read -r line; do
	printf "    ${YELLOW}%s${RC}\n" "\$line";
done
# printf '\n';
$task
CMDC

	if test "${#cmdc}" -gt 4096; then {
		printf '%s\n' "$cmdc" > "$cmdc_tmp_file";
		cmdc="$(
			printf 'eval "$(< "%s")"\n' "$cmdc_tmp_file";
		)";
	} fi

	printf '%s\n' "$cmdc";
}


function config::tmux::hijack_gitpod_task_terminals {
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
					if ! grep -q "^$dotfiles_notmux_sig\$" <<<"$stdin"; then {
						# Terminate gitpod created task terminals so that we can take over,
						# previously this was done in a more complicated way via `tmux_old.sh:tmux::inject_old_complicated()` :P
						exit 0;
					} fi
				} fi

			} else {

				local stdin cmd;
				IFS= read -t0.01 -u0 -r -d '' stdin || :;

				if test -n "$stdin"; then {
					cmd="$(get::task_cmd)";
					exec bash -lic "$cmd";
				} fi

			} fi
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
		printf '%s\n' "tmux_first_session_name=$tmux_first_session_name" \
						"tmux_first_window_num=$tmux_first_window_num" \
						"$(declare -f "${function_exports[@]}")" \
						"DOTFILES_TMUX=${DOTFILES_TMUX:-true}" \
						"dotfiles_notmux_sig=$dotfiles_notmux_sig" \
						"DOTFILES_TMUX_NO_VSCODE=${DOTFILES_TMUX_NO_VSCODE:-false}" \
						'PROMPT_COMMAND="tmux::inject; $PROMPT_COMMAND"' >> "$HOME/.bashrc";
	} fi
}



function config::tmux() {

	# In case tmux feature is disabled
	# TODO: Don't do this
	if test "${DOTFILES_TMUX:-true}" != true; then {
		await::signal send config_tmux;
		return;
	} fi

	log::info "Setting up tmux";
	
	if is::cde; then {
		# Lock on tmux binary
		# local check_file=(/nix/store/*-tmux-*/bin/tmux);
		# local tmux_exec_path;

		# if test -n "${check_file:-}"; then {
		# 	tmux_exec_path="${check_file[0]}";
		# 	KEEP=true await::create_shim "$tmux_exec_path";
		# } else {
		# 	tmux_exec_path="/usr/bin/tmux";
		# 	KEEP="true" SHIM_MIRROR="$HOME/.nix-profile/bin/tmux" \
		# 		await::create_shim "$tmux_exec_path";
		# } fi
		declare tmux_exec_path=/usr/bin/tmux;
		# await::until_true command::exists "$tmux_exec_path";
		KEEP=true SHIM_MIRROR="/usr/bin/.dw/tmux" await::create_shim "$tmux_exec_path";
	} else {
		await::until_true command::exists tmux;
	} fi

	if is::gitpod; then {
		if test "${DOTFILES_SPAWN_SSH_PROTO:-true}" == true; then {
			tmux::start_vimpod & disown;
		} fi
		config::tmux::hijack_gitpod_task_terminals & wait;
	} fi

	{
		await::signal get install_dotfiles;
		local target="$HOME/.tmux/plugins/tpm";
		if test ! -e "$target"; then {
			git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target" >/dev/null 2>&1;
		} fi
		"$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh";
	
		await::signal send config_tmux;

		if is::cde; then {
			tmux_create_session;
		} fi

		CLOSE=true await::create_shim "${tmux_exec_path:-}";
	
		(
			if is::gitpod; then {
				await::until_true command::exists yq;

				if test "${DOTFILES_READ_GITPOD_YML:-}" == true; then {
					declare gitpod_yml=("${GITPOD_REPO_ROOT:-}/".gitpod.y*ml);
					if test -n "${gitpod_yml:-}" && gitpod_yml="${gitpod_yml[0]}"; then {
						if ! GITPOD_TASKS="$(yq -I0 -erM -o=json '.tasks' "$gitpod_yml" 2>&1)"; then {
							log::warn "No .gitpod.yml:tasks were found";
							return;
						} fi
					} fi
				} fi

				if test -z "${GITPOD_TASKS:-}"; then {
					return;
				} else {
					log::info "Spawning Gitpod tasks in tmux";
				} fi

			} elif is::codespaces && test -e "${CODESPACES_VSCODE_FOLDER:-}"; then {
				cd "$CODESPACE_VSCODE_FOLDER" || true;
				return;
			} else {
				return;
			} fi

			await::for_file_existence "$workspace_dir/.gitpod/ready";
			cd "${GITPOD_REPO_ROOT:-}";

			function jqw() {
				local cmd;
				if cmd=$(yq -o=json -I0 -erM "$@" <<<"$GITPOD_TASKS"); then {
					printf '%s\n' "$cmd";
				} else {
					return 1;
				} fi
			} 2>/dev/null

			local name cmd arr_elem=0;
			local cmd_tmp_file="/tmp/.tmux_gpt_cmd";
			while {
				success=0;
				cmd_prebuild="$(jqw ".[${arr_elem}] | [.init] | map(select(. != null)) | .[]")" && ((success=success+1));
				cmd_others="$(jqw ".[${arr_elem}] | [.before, .command] | map(select(. != null)) | .[]")" && ((success=success+1));
				test $success -gt 0;
			}; do {
				if ! name="$(jqw ".[${arr_elem}].name")"; then {
					name="AnonTask-${arr_elem}";
				} fi

				local prebuild_log="$workspace_dir/.gitpod/prebuild-log-${arr_elem}";
				
				cmd="$(
					if test -e "$prebuild_log"; then {
						printf 'cat %s\n' "$prebuild_log";
						printf '%s\n' "${cmd_others:-}";
					} else {
						printf '%s\n' "${cmd_prebuild:-}" "${cmd_others:-}";
					} fi
				)";

				if ! grep -q "^${dotfiles_notmux_sig}\$" <<<"$cmd"; then {
					cmd="$(get::task_cmd "$cmd")";
					WINDOW_NAME="$name" tmux_create_window -d -- bash -lic "$cmd";
				} fi

				((arr_elem=arr_elem+1));
			} done

		) & disown;
		
		# if test "$(tmux display-message -p '#{session_windows}')" -le 2; then {
		# 	sleep 1;
		# } fi 

		
		await::signal send config_tmux_session;

		if is::gitpod; then {

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

i=1 && while true; do {
	# Read all properties
	IFS=$'\n' read -d '' -r mem_used mem_max cpu_used cpu_max \
		< <(gp top -j | yq -I0 -rM ".resources | [.memory.used, .memory.limit, .cpu.used, .cpu.limit] | .[]")

	# Human friendly memory numbers
	read -r hmem_used hmem_max < <(numfmt -z --to=iec --format="%8.2f" $mem_used $mem_max);

	# CPU percentage
	cpu_perc="$(( (cpu_used * 100) / cpu_max ))";

  # Disk usage
  if test "${i:0-1}" == 1; then
    read -r dsize dused < <(df -h --output=size,used /workspace | tail -n1)
  fi

	# Print to tmux
	printf '%s\n' " #[bg=#ffb86c,fg=#282a36,bold] CPU: ${cpu_perc}% #[bg=#8be9fd,fg=#282a36,bold] MEM: ${hmem_used%?}/${hmem_max} #[bg=green,fg=#282a36,bold] DISK: ${dused}/${dsize} ";
	sleep 3;
  ((i=i+1));
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

		} fi
	 } & disown;
}
