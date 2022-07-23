use std::io::stdio;

local -r _shell_hist_files=(
    "$HOME/.bash_history"
    "$HOME/.zsh_history"
    "$HOME/.local/share/fish/fish_history"
)

function shell::persist_history() {
    # Use workspace persisted history
    log::info "Persiting Gitpod shell histories to /workspace";
    local _workspace_persist_dir="/workspace/.persist";
    mkdir -p "$_workspace_persist_dir";
    local _hist;
    for _hist in "${_shell_hist_files[@]}"; do {
        mkdir -p "${_hist%/*}";
        _hist_name="${_hist##*/}";
        if test -e "$_workspace_persist_dir/$_hist_name"; then {
            log::warn "Overwriting $_hist with workspace persisted history file";
            ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist";
        } else {
            touch "$_hist";
            cp "$_hist" "$_workspace_persist_dir/";
            ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist";
        } fi
        unset _hist_name;
    } done
}
function shell::hijack_gitpod_task_terminals() {
    # Make gitpod task spawned terminals use fish
    if ! grep -q 'PROMPT_COMMAND="inject_tmux;.*"' "$HOME/.bashrc"; then {
    log::info "Setting tmux as the interactive shell for Gitpod task terminals"
		function inject_tmux() {
			function create_window() {
				cmd() {
					exec tmux new-window -n "vs:${PWD##*/}" -t main "$@";
				}
				# read -n 1 -rs -p "$(printf '\n\n>>> Press any key for switching to tmux or Ctrl+c to exit')" || exit;
				local tmux_init_lock=/tmp/.tmux.init;
				if test -e "$tmux_init_lock"; then {
					# create_window "$tmux_default_shell" -l;
					cmd "$@";
				} else {
					touch "$tmux_init_lock";
					(cd $HOME && tmux new-session -n home -ds main 2> /dev/null || :);
					cmd "$@" \; attach;
				} fi
			}
			# The supervisor creates the task terminals, supervisor calls BASH from `/bin/bash` instead of the realpath `/usr/bin/bash`
			if [ "$BASH" == /bin/bash ]; then {
				# if test ! -v TMUX; then {
				# 	create_window "$BASH" -l \; attach;
				# } fi
				stdout_file=/tmp/.stdout.$$;
				stderr_file=/tmp/.stderr.$$;
				if test ! -v bash_ran_once; then {
					io::stdio::to_file "$stdout_file" "$stderr_file";
				} fi
				if test -v bash_ran_once && [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ]; then {
					can_switch=true;
				} fi

				# local hist_cmd="history -a /dev/stdout";
				# if test -z "$($hist_cmd)"; then {
				# 	can_switch=true;
				# 	echo emp
				# } fi

				if test -v can_switch; then {
					tmux_default_shell="$(tmux display -p '#{default-shell}')";
					create_window "printf '>>>>> STDOUT\n%s\n\n>>>>> STDERR\n%s' (cat $stdout_file) (cat $stderr_file); exec $tmux_default_shell -l";
					TRUE
				} else {
					bash_ran_once=true;
				} fi
			} else {
				unset ${FUNCNAME[0]} && PROMPT_COMMAND="${PROMPT_COMMAND/${FUNCNAME[0]};/}";
			} fi

		}
		printf '%s\n' "$(declare -f io::stdio::to_file)" "$(declare -f inject_tmux)" 'PROMPT_COMMAND="inject_tmux;$PROMPT_COMMAND"' >> "$HOME/.bashrc";
    } fi
}

function fish::append_hist_from_gitpod_tasks() { 
    # Append .gitpod.yml:tasks hist to fish_hist
    log::info "Appending .gitpod.yml:tasks shell histories to fish_history";
    while read -r _command; do {
        if test -n "$_command"; then {
            printf '\055 cmd: %s\n  when: %s\n' "$_command" "$(date +%s)" >> "${_shell_hist_files[2]}";
        } fi 
    } done < <(sed "s/\r//g" /workspace/.gitpod/cmd-* 2>/dev/null || :)
}


function bash::gitpod_start_tmux_on_start() {
	local file="$HOME/.bashrc.d/10-tmux";
	printf '(cd $HOME && tmux new-session -n home -ds main 2>/dev/null || :) & rm %s\n' "$file" > "$file";
}