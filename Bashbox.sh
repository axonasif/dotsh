# shellcheck disable=SC2034

NAME="dotfiles"
CODENAME="dotfiles"
AUTHORS=("AXON <axonasif@gmail.com>")
VERSION="1.0"
DEPENDENCIES=(
	std::15dc26b
)
REPOSITORY="https://github.com/axonasif/dotfiles.git"
BASHBOX_COMPAT="0.3.9~"

bashbox::build::after() {
	local _script_name='install.sh';
	local root_script="$_arg_path/$_script_name";
	cp "$_target_workfile" "$root_script";
	chmod +x "$root_script";
	# DEBUG
	sed -i 's|#!/home/gitpod/.nix-profile/bin|#!/usr/bin|g' "$root_script";
}

bashbox::build::before() {
	# TODO: Port to std
	local git_dir="$_arg_path/.git";
	local hooks_dir="$git_dir/hooks";
	local pre_commit_hook="$hooks_dir/pre-commit";
	if test -e "$git_dir" && test ! -e "$pre_commit_hook"; then {
		log::info "Setting up pre-commit git hook";
		mkdir -p "$hooks_dir";
		printf '%s\n' \
					'#!/usr/bin/env sh' \
					'bashbox build --release' \
					'git add install.sh' > "$pre_commit_hook";
		chmod +x "$pre_commit_hook";
	} fi
}

live() (
	local container_image="axonasif/dotfiles-testing:latest"; # From src/.testing.Dockerfile
	source "$_arg_path/src/utils/common.sh";

	cmd="bashbox build --release";
	log::info "Running $cmd";
	$cmd || exit 1;

	local duplicate_workspace_root="/tmp/.mrroot";
	local workspace_sources;
	if test -n "${GITPOD_REPO_ROOTS:-}"; then {
		local repo_roots;
		IFS=',' read -ra workspace_sources <<<"$GITPOD_REPO_ROOTS";
	} else {
		workspace_sources=("${_arg_path}");
	} fi

	log::info "Creating a clone of ${workspace_sources[0]} at $duplicate_workspace_root" && {
		rm -rf "$duplicate_workspace_root";
		mkdir -p "$duplicate_workspace_root";
		cp -ra "${workspace_sources[@]}" "$duplicate_workspace_root";
		if test -e /workspace/.gitpod; then {
			cp -ra /workspace/.gitpod "$duplicate_workspace_root";
		} fi
	}

	# local ide_mirror="/tmp/.idem";
	# if test ! -e "$ide_mirror"; then {
	# 	log::info "Creating /ide mirror";
	# 	cp -ra /ide "$ide_mirror";
	# } fi

	log::info "Starting a fake Gitpod workspace with headless IDE" && {
		# local ide_cmd ide_port;
		# ide_cmd="$(ps -p $(pgrep -f 'sh /ide/bin/gitpod-code' | head -n1) -o args --no-headers)";
		# ide_port="33000";
		# ide_cmd="${ide_cmd//23000/${ide_port}} >/ide/server_log 2>&1";

		local docker_args=();
		docker_args+=(
			run
			--rm
			--net=host
		)

		docker_args+=(
			# Shared mountpoints
			-v "$duplicate_workspace_root:/workspace"
			-v "$_arg_path:$HOME/.dotfiles"
		)

		if is::gitpod; then {
			docker_args+=(
				# IDE mountpoints
				# -v "$ide_mirror:/ide"
				-v /usr/bin/gp:/usr/bin/gp:ro
				# Required for rclone
				--privileged
				--device /dev/fuse
				# Docker socket
				-v /var/run/docker.sock:/var/run/docker.sock
			)
		} fi
		
		local dotfiles_sh_dir="$HOME/.dotfiles-sh";
		if test -e "$dotfiles_sh_dir"; then {
			docker_args+=(
				-v "$dotfiles_sh_dir:$dotfiles_sh_dir"
			)
		} fi

		if is::gitpod; then {
			docker_args+=(
				# Environment vars
				-e GP_EXTERNAL_BROWSER
				-e GP_OPEN_EDITOR
				-e GP_PREVIEW_BROWSER
				-e GITPOD_ANALYTICS_SEGMENT_KEY
				-e GITPOD_ANALYTICS_WRITER
				-e GITPOD_CLI_APITOKEN
				-e GITPOD_GIT_USER_EMAIL
				-e GITPOD_GIT_USER_NAME
				-e GITPOD_HOST
				-e GITPOD_IDE_ALIAS
				-e GITPOD_INSTANCE_ID
				-e GITPOD_INTERVAL
				-e GITPOD_MEMORY
				-e GITPOD_OWNER_ID
				-e GITPOD_PREVENT_METADATA_ACCESS
				-e GITPOD_REPO_ROOT
				-e GITPOD_REPO_ROOTS
				-e GITPOD_THEIA_PORT
				-e GITPOD_WORKSPACE_CLASS
				-e GITPOD_WORKSPACE_CLUSTER_HOST
				-e GITPOD_WORKSPACE_CONTEXT
				-e GITPOD_WORKSPACE_CONTEXT_URL
				-e GITPOD_WORKSPACE_ID
				-e GITPOD_WORKSPACE_URL
				# Fake gitpod tasks for testing
				-e GITPOD_TASKS='[{"name":"Test foo","command":"echo This is fooooo"},{"name":"Test boo", "command":"echo This is boooo"}]'

				# !! Note: the DOTFILES_ env vars could be overwritten by https://gitpod.io/variables even if you set them here.
				# Disable ssh:// protocol launch
				-e DOTFILES_SPAWN_SSH_PROTO=false
				## These options below are also available, see README.md for more info
				# -e DOTFILES_DEFAULT_SHELL=zsh
				# -e DOTFILES_TMUX=false
			)
		} fi

		docker_args+=(
			# Container image
			-it "$container_image"
		)

		function startup_command() {
			export PATH="$HOME/.nix-profile/bin:$PATH";
			local logfile="$HOME/.dotfiles.log";
			# local tail_cmd="less -S -XR +F $logfile";
			local tail_cmd="tail -f $logfile"
			eval "$(gp env -e)";
			set +m; # Temporarily disable job control
			{ "$HOME/.dotfiles/install.sh" 2>&1; } >"$logfile" 2>&1 & wait;
			set -m;

			(
				until tmux has-session 2>/dev/null; do sleep 1; done;
				pkill -9 -f "${tail_cmd//+/\\+}" || :;
				tmux setw -g mouse on;
				until test -n "$(tmux list-clients)"; do sleep 1; done;
				printf '====== %% %s\n' \
					"Run 'tmux detach' to exit from here" \
					"Press 'ctrl+c' to exit the log-pager" \
					"You can click between tabs/windows in the bottom" >> "$logfile";
				tmux select-window -t :1;
				sleep 2;
				tmux detach-client;
			) & disown;

			if test "${DOTFILES_TMUX:-true}" == true; then {
				$tail_cmd;
				AWAIT_SHIM_PRINT_INDICATOR=true tmux new-window -n ".dotfiles.log" "$tail_cmd" \; attach;
			} else {
				(sleep 2 && $tail_cmd) &
				exec "${DOTFILES_DEFAULT_SHELL:-bash}" -li;
			} fi

			# # Fallback
			# if test $? != 0; then {
			# 	printf '%s\n' "PS1='testing-dots \w \$ '" >> "$HOME/.bashrc";
			# 	printf 'INFO: \n\n%s\n\n' "Falling back to debug bash shell";
			# 	exec bash -li;
			# } fi
		}

		if is::gitpod; then {
			docker_args+=(
				# Startup command
				 /bin/bash -li
			)
		} else {
			docker_args+=(
				/bin/bash -li
			)
		} fi
		local confirmed_statfile="/tmp/.confirmed_statfile";
		touch "$confirmed_statfile";
		local confirmed_times="$(( $(<"$confirmed_statfile") + 1 ))";
		if [[ "$confirmed_times" -lt 3 ]]; then {
			printf '\n';
			printf 'INFO: %b\n' "Now this will boot into a simulated Gitpod workspace" \
								"To exit from there, you can press ${BGREEN}Ctrl+d${RC} or run ${BRED}exit${RC} on the terminal when in ${GRAY}bash${RC} shell" \
								"You can run ${ORANGE}tmux${RC} a on the terminal to attach to the tmux session where Gitpod tasks are opened as tmux-windows" \
								"To exit detach from the tmux session, you can run ${BPURPLE}tmux detach${RC}"
			printf '\n';
			read -r -p '>>> Press Enter/return to continue execution of "bashbox live" command';
			printf '%s\n' "$confirmed_times" > "$confirmed_statfile";
		} fi

		local lckfile="/workspace/.dinit";
		if test -e "$lckfile" && test ! -s "$lckfile"; then {
			printf 'info: %s\n' "Waiting for the '.gitpod.yml:tasks:command' docker-pull to complete ...";
			until test -s "$lckfile"; do {
				sleep 0.5;
			} done
			rm -f "$lckfile";
		} fi

		docker "${docker_args[@]}" -c "$(printf "%s\n" "$(declare -f startup_command)" "startup_command")";
	}

)



