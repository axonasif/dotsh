function config::shell::fish() {
	if is::cde; then {
		# Lock on fish binary
		local check_file=(/nix/store/*-fish-*/bin/fish);
		local fish_exec_path;

		if test -n "${check_file:-}"; then {
			fish_exec_path="${check_file[0]}";
			KEEP=true await::create_shim "$fish_exec_path";
		} else {
			fish_exec_path="/usr/bin/fish";
			KEEP="true" SHIM_MIRROR="$HOME/.nix-profile/bin/fish" \
				await::create_shim "$fish_exec_path";
		} fi
	} else {
		await::until_true command::exists $HOME/.nix-profile/bin/fish;
	} fi

	# Install fisher plugin manager
	log::info "Installing fisher and some plugins for fish-shell";

	mkdir -p "$fish_confd_dir";
	{
		fish -c "curl -sL https://git.io/fisher | source && fisher install ${fish_plugins[*]}"

		# Fisher plugins
		# fish -c 'fisher install lilyball/nix-env.fish'; # Might not be necessary because of my own .config/fish/conf.d/bash_env.fish
	} >/dev/null 2>&1

	CLOSE=true await::create_shim "$fish_exec_path";
}

function config::shell::fish::append_hist_from_gitpod_tasks() {
	await::signal get install_dotfiles;
	# Append .gitpod.yml:tasks hist to fish_hist
	log::info "Appending .gitpod.yml:tasks shell histories to fish_history";
	mkdir -p "${fish_hist_file%/*}";
	while read -r _command; do {
		if test -n "$_command"; then {
			printf '\055 cmd: %s\n  when: %s\n' "$_command" "$(date +%s)" >> "$fish_hist_file";
		} fi 
	} done < <(sed "s/\r//g" /workspace/.gitpod/cmd-* 2>/dev/null || :)
}