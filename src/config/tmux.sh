use std::term::colors;
use libtmux::session;
use libtmux::window;

function tmux_create_session() {
  SESSION_NAME="$tmux_first_session_name" \
  WINDOW_NAME="editor" \
  DEBUG_SHIM="true" tmux::new-session -c "${GITPOD_REPO_ROOT:-$HOME}" \
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
    sudo sh -c "printf '%s\n' 'set-option -g base-index 1' >> /etc/tmux.conf";
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
		"$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" || true;
	
		await::signal send config_tmux;

		if is::cde; then {
			tmux_create_session;
      CLOSE=true await::create_shim "${tmux_exec_path:-}";
		} fi
	
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
      declare plugin_path="/etc/gitpod.tmux";
      dw "$plugin_path" "https://raw.githubusercontent.com/axonasif/gitpod.tmux/main/gitpod.tmux";
      cat <<EOF | sudo tee -a /etc/tmux.conf 1>/dev/null
run-shell -b 'until test -n "\$(tmux list-clients 2>/dev/null)"; do sleep 1; done; exec $plugin_path'
EOF
		} fi

	until tmux list-clients 2>/dev/null; do sleep 1; done
    "$plugin_path";
		
	 } & disown;
}
