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
function config::shell::hijack_gitpod_task_terminals() {
    # Make gitpod task spawned terminals use fish
    if ! grep -q 'PROMPT_COMMAND="inject_tmux;.*"' "$HOME/.bashrc"; then {
    log::info "Setting tmux as the interactive shell for Gitpod task terminals"
		function inject_tmux() {
			(cd $HOME && tmux new-session -n home -ds main 2> /dev/null || :);
			function create_window() {
				cmd() {
					exec tmux new-window -n "vs:${PWD##*/}" -t main "$@";
				}
				# read -n 1 -rs -p "$(printf '\n\n>>> Press any key for switching to tmux or Ctrl+c to exit')" || exit;
				local tmux_init_lock=/tmp/.tmux.init;
				if test ! -e "$tmux_init_lock"; then {
					# create_window "$tmux_default_shell" -l;
					touch "$tmux_init_lock";
					local tasks_count;
					# tasks_count="$(echo $GITPOD_TASKS | grep -Eo '(before|command|init)":"' | wc -l)"
					# if test "$tasks_count" -eq 1; then {
						cmd "$@" \; attach;
					# } else {
						# cmd "$@";
					# } fi
				} else {
					cmd "$@";
				} fi
				
			}
			# The supervisor creates the task terminals, supervisor calls BASH from `/bin/bash` instead of the realpath `/usr/bin/bash`
			if [ "$BASH" == /bin/bash ] || [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ] && test ! -v SSH_CONNECTION; then {
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
					# read -p running
					(
						printf '%s' "$stdin";
						eval "$stdin"
					) || :;
					can_switch=true;
				} else {
					# read -p exiting
					exit;
				} fi

				if test -v can_switch; then {
					# read -p waiting;
					tmux_default_shell="$(tmux display -p '#{default-shell}')";
					create_window "less -FXR $termout | cat; exec $tmux_default_shell -l";
				} else {
					bash_ran_once=true;
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


function config::shell::bash::gitpod_start_tmux_on_start() {
	local file="$HOME/.bashrc.d/10-tmux";
	printf '(cd $HOME && tmux new-session -n home -ds main 2>/dev/null || :) & rm %s\n' "$file" > "$file";
}

function config::shell::vscode::set_tmux_as_default_shell() {
	log::info "Setting the integrated tmux shell for VScode as default";
	vscode::add_settings "$source_dir/src/config/shell_settings.json";
}