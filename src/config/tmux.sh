use std::term::colors;
use libtmux::session;
use libtmux::window;

function tmux_create_session() {
	SESSION_NAME="$tmux_first_session_name" \
  WINDOW_NAME="editor" \
    tmux::new-session -c "${GITPOD_REPO_ROOT:-$HOME}" \
      -- "$(get::default_shell)" -li 2>/dev/null || :;
}

function tmux_create_window() {
  SESSION_NAME="$tmux_first_session_name" tmux::new-window "$@";
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
				} else {
					cmd="$(
						cat <<-EOF
						printf '>> %s\n' \
							"This was ignored to be run inside tmux via '$dotfiles_notmux_sig' flag inside the task codeblock" \
							"If you wish to open this on tmux, you may use 'gp tasks list' to get the running TaskID, and then 'gp tasks attach <TaskID>'";
						read -r -n 1 -p ">> Press Enter to dismiss";
						EOF
					)";
				} fi

				WINDOW_NAME="$name" tmux_create_window -d -- bash -lic "$cmd";

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
