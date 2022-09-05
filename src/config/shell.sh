local -r _shell_hist_files=(
	"${HISTFILE:-"$HOME/.bash_history"}"
	"${HISTFILE:-"$HOME/.zsh_history"}"
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

function config::shell::fish::append_hist_from_gitpod_tasks() { 
	# Append .gitpod.yml:tasks hist to fish_hist
	log::info "Appending .gitpod.yml:tasks shell histories to fish_history";
	while read -r _command; do {
		if test -n "$_command"; then {
			printf '\055 cmd: %s\n  when: %s\n' "$_command" "$(date +%s)" >> "${_shell_hist_files[2]}";
		} fi 
	} done < <(sed "s/\r//g" /workspace/.gitpod/cmd-* 2>/dev/null || :)
}

