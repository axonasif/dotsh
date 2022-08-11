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
			if [ "$BASH" == /bin/bash ] || [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ]; then {
				# if test ! -v TMUX; then {
				# 	create_window "$BASH" -l \; attach;
				# } fi

				if [[ ! -t 0 ]]; then {
					stdin="$(< /dev/stdin)"
					if test -n "$stdin"; then {
						echo "$stdin";
						eval "$stdin";
					} else {
						exit;
					} fi
				} fi

				termout=/tmp/.termout.$$
				if test ! -v bash_ran_once; then {
					exec > >(tee -a "$termout") 2>&1;
				} fi
				if test -v bash_ran_once; then {
					can_switch=true;
				} fi

				# local hist_cmd="history -a /dev/stdout";
				# if test -z "$($hist_cmd)"; then {
				# 	can_switch=true;
				# 	echo emp
				# } fi

				if test -v can_switch; then {
					tmux_default_shell="$(tmux display -p '#{default-shell}')";
					create_window "less -FXR $termout | cat; exec $tmux_default_shell -l";
					TRUE
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

function vscode::set_default_shell() {
	log::info "Setting the integrated tmux shell for VScode as default";
	local settings_name="terminal.integrated.profiles.linux";
	local machine_settings_file="/workspace/.vscode-remote/data/Machine/settings.json";
	set -x
	if ! grep -q "$settings_name" "$machine_settings_file" 2>/dev/null; then {
		if test ! -e "$machine_settings_file"; then {
			mkdir -p "${machine_settings_file%/*}"
			cat << 'EOF' > "$machine_settings_file"
{			
	//// Terminal config
	"terminal.integrated.profiles.linux": {
		"tmuxshell": {
			"path": "bash",
			"args": [
				"-c",
				"tmux new-session -ds main 2>/dev/null || :; { [ -z \"$(tmux list-clients -t main)\" ] && attach=true || for cpid in $(tmux list-clients -t main -F '#{client_pid}'); do spid=$(ps -o ppid= -p $cpid);pcomm=\"$(ps -o comm= -p $spid)\"; [[ \"$pcomm\" =~ (Code|vscode|node|supervisor) ]] && attach=false && break; done; test \"$attach\" != false && exec tmux attach -t main; }; exec tmux new-window -n \"vs:${PWD##*/}\" -t main"
			]
		}
	},

	"terminal.integrated.defaultProfile.linux": "tmuxshell",
}
EOF

			# printf '{\n\t"%s": "%s"\n}\n' "$settings_name" "$settings_value" > "$machine_settings_file"
		# } else {
			# sed -i "1s|^{|{ \"$settings_name\": \"$settings_value\"\n|" "$machine_settings_file"
		} fi
	} fi
}