local -r _shell_hist_files=(
    "$HOME/.bash_history"
    "$HOME/.zsh_history"
    "$HOME/.local/share/fish/fish_history"
)

function config::shell::persist_history() {
    # Use workspace persisted history
    log::info "Persiting Gitpod shell histories to /workspace";
    local _workspace_persist_dir="/workspace/.persist";
    mkdir -p "$_workspace_persist_dir";
    local _hist;
    for _hist in "${_shell_hist_files[@]}"; do {
        mkdir -p "${_hist%/*}";
        _hist_name="${_hist##*/}";
        if test -e "$_workspace_persist_dir/$_hist_name"; then {
            log::info "Overwriting $_hist with workspace persisted history file";
            ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist";
        } else {
            touch "$_hist";
            cp "$_hist" "$_workspace_persist_dir/";
            ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist";
        } fi
        unset _hist_name;
    } done
}
function config::shell::hijack_gitpod_task_terminals() {
	# For debugging
	# trap 'read -p eval: && eval "$REPLY"' ERR EXIT SIGTERM SIGINT
    
	# Make gitpod task spawned terminals use fish
    if ! grep -q 'PROMPT_COMMAND=".*inject_tmux.*"' "$HOME/.bashrc" 2>/dev/null; then {
    log::info "Setting tmux as the interactive shell for Gitpod task terminals"
		function inject_tmux() {
			function create_session() {
				tmux new-session -n home -ds main|| :;
				tmux send-keys -t main "cat $HOME/.dotfiles.log" Enter;
				tmux_default_shell="$(tmux display -p '#{default-shell}')";
				# local tmux_default_shell;
				# tmux_default_shell="$(tmux start-server\; display -p '#{default-shell}')";
			}
			function new_window() {
				exec tmux new-window -n "${WINDOW_NAME:-vs:${PWD##*/}}" -t main "$@";
			}
			function create_window() {
				local tmux_init_lock=/tmp/.tmux.init;
				if test ! -e "$tmux_init_lock"; then {
					# create_window "$tmux_default_shell" -l;
					touch "$tmux_init_lock";
					# local tasks_count;
					# tasks_count="$(echo $GITPOD_TASKS | grep -Eo '(before|command|init)":"' | wc -l)"
					# if test "$tasks_count" -eq 1; then {
						new_window "$@" \; attach;
					# } else {
						# cmd "$@";
					# } fi
				} else {
					new_window "$@";
				} fi		
			}

			create_session;

			# The supervisor creates the task terminals, supervisor calls BASH from `/bin/bash` instead of the realpath `/usr/bin/bash`
			if test ! -v TMUX && [ "$BASH" == /bin/bash ] || [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ]; then {
				if test -v SSH_CONNECTION; then {
					# Connect task terminals to tmux windows
					local term_id term_name task_state symbol ref;
					while IFS='|' read -r _ term_id term_name task_state _; do {
						if [[ "$term_id" =~ [0-9]+ ]]; then {
							for symbol in term_id term_name task_state; do {
								declare -n ref="$symbol";
								ref="${ref% }" && ref="${ref# }";
							} done
							echo "$term_id:$term_name:$task_state";
							if test "$task_state" == "running"; then {
								(WINDOW_NAME="${term_name}" new_window gp tasks attach "$term_id")
							} fi
							unset symbol ref;
						} fi
					} done < <(gp tasks list --no-color)
					exec tmux attach-session -t main;
				} else {
					# if test ! -v TMUX; then {
					# 	create_window "$BASH" -l \; attach;
					# } fi

					termout=/tmp/.termout.$$
					if test ! -v bash_ran_once; then {
						exec > >(tee -a "$termout") 2>&1;
					} fi
					if test -v bash_ran_once; then {
						can_switch=true;
					} fi

					local stdin;
					IFS= read -t0.01 -u0 -r -d '' stdin;
					if test -n "$stdin"; then {
						# declare -p stdin
						# read -p running
						# (
							# set -x
							stdin=$(printf '%q' "$stdin")
							create_window bash -c "trap 'exec $tmux_default_shell -l' EXIT; less -FXR $termout | cat; printf '%s\n' $stdij; eval $stdin;";
							# exit; 
							# eval "$stdin"
						# ) || :;
						# can_switch=true;
					} else {
						# read -p exiting
						exit;
					} fi

					# if test -v can_switch; then {
						# read -p waiting;
					# 	create_window "less -FXR $termout | cat; exec $tmux_default_shell -l";
					# } else {
						bash_ran_once=true;
					# } fi
				} fi
			} else {
				unset ${FUNCNAME[0]} && PROMPT_COMMAND="${PROMPT_COMMAND/${FUNCNAME[0]};/}";
			} fi

		}
		printf '%s\n' "$(declare -f inject_tmux)" 'PROMPT_COMMAND="inject_tmux;$PROMPT_COMMAND"' >> "$HOME/.bashrc";
    } fi
}

function config::shell::fish::append_hist_from_gitpod_tasks() { 
    # Append .gitpod.yml:tasks hist to fish_hist
    log::info "Appending .gitpod.yml:tasks shell histories to fish_history";
    while read -r _command; do {
        if test -n "$_command"; then {
            printf '\055 cmd: %s\n  when: %s\n' "$_command" "$(date +%s)" >> "${_shell_hist_files[2]}";
        } fi 
    } done < <(sed "s/\r//g" /workspace/.gitpod/cmd-* 2>/dev/null || :)
}




function config::shell::vscode::set_tmux_as_default_shell() {
	log::info "Setting the integrated tmux shell for VScode as default";
	vscode::add_settings <<-'JSON'
		{
			"terminal.integrated.profiles.linux": {
				"tmuxshell": {
					"path": "bash",
					"args": [
						"-c",
						"tmux new-session -ds main 2>/dev/null || :; { [ -z \"$(tmux list-clients -t main)\" ] && attach=true || for cpid in $(tmux list-clients -t main -F '#{client_pid}'); do spid=$(ps -o ppid= -p $cpid);pcomm=\"$(ps -o comm= -p $spid)\"; [[ \"$pcomm\" =~ (Code|vscode|node|supervisor) ]] && attach=false && break; done; test \"$attach\" != false && exec tmux attach -t main; }; exec tmux new-window -n \"vs:${PWD##*/}\" -t main"
					]
				}
			},
			"terminal.integrated.defaultProfile.linux": "tmuxshell"
		}
	JSON
}