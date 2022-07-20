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
function fish::hijack_gitpod_tasks() {
    # Make gitpod task spawned terminals use fish
    log::info "Setting fish as the interactive shell for Gitpod task terminals"
    if ! grep 'PROMPT_COMMAND=".*exec fish"' $HOME/.bashrc 1>/dev/null; then {
        # The supervisor creates the task terminals, supervisor calls BASH from `/bin/bash` instead of the realpath `/usr/bin/bash`
        printf '%s\n' 'PROMPT_COMMAND="[ "$BASH" == /bin/bash ] && [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ] && test -v bash_ran && exec fish || bash_ran=true;$PROMPT_COMMAND"' >> $HOME/.bashrc;
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

function fish::inherit_bash_env() {
    local hook_snippet="eval (~/.bprofile2fish)";
	local fish_histfile="${_shell_hist_files[2]}";
    if ! grep -q "$hook_snippet" "$fish_histfile"; then {
        log::info "Injecting bash env into fish";
        printf '%s\n' "$hook_snippet" >> "$fish_histfile";
    } fi
}