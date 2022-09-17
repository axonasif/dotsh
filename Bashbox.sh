# shellcheck disable=SC2034

NAME="dotfiles"
CODENAME="dotfiles"
AUTHORS=("AXON <axonasif@gmail.com>")
VERSION="1.0"
DEPENDENCIES=(
	std::HEAD
)
REPOSITORY="https://github.com/axonasif/dotfiles.git"
BASHBOX_COMPAT="0.3.9~"

bashbox::build::after() {
	local _script_name='install.sh';
	local root_script="$_arg_path/$_script_name";
	cp "$_target_workfile" "$root_script";
	chmod +x "$root_script";
}

bashbox::build::before() {
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
	local container_image="gitpod/workspace-base:latest";
	source "$_arg_path/src/utils/common.sh";
	rm -f "$_arg_path/.last_applied";

	local offline_dotfiles_repo="${_arg_path%/*}/dotfiles.public";
	if test -v DOTFILES_PRIMARY_REPO; then {
		git clone "$DOTFILES_PRIMARY_REPO" "$offline_dotfiles_repo";
	} fi

	log::info "Using $offline_dotfiles_repo as the raw dotfiles repo";

	# if test "$1" == "r"; then {
		cmd="bashbox build --release";
		log::info "Running '$cmd";
		$cmd;
	# } fi

	local duplicate_workspace_root="/tmp/.mrroot";
	local duplicate_repo_root="$duplicate_workspace_root/${_arg_path##*/}";

	log::info "Creating a clone of $_arg_path at $duplicate_workspace_root" && {
		rm -rf "$duplicate_workspace_root";
		mkdir -p "$duplicate_workspace_root";
		cp -ra "$_arg_path" "$duplicate_workspace_root";
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
			-v "$duplicate_repo_root:$HOME/.dotfiles"
		)

		if is::gitpod; then {
			docker_args+=(
				# IDE mountpoints
				# -v "$ide_mirror:/ide"
				-v /usr/bin/gp:/usr/bin/gp:ro
			)
		} fi
		
		docker_args+=(
			# Use offline dotfiles repo
			-e DOTFILES_PRIMARY_REPO="$offline_dotfiles_repo"
			-v "$offline_dotfiles_repo:$offline_dotfiles_repo"
		)

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
				-e GITPOD_TASKS
				# Disable ssh:// protocol launch
				-e DOTFILES_SPAWN_SSH_PROTO=false
			)
		} fi

		docker_args+=(
			# Container image
			-it "$container_image"
		)

		function startup_command() {
			local logfile="$HOME/.dotfiles.log";
			eval "$(gp env -e)";
			set +m;
			"$HOME/.dotfiles/install.sh";
			set -m;
			# tail -F "$logfile" & disown;
			printf '%s\n' "PS1='testing-dots \w \$ '" >> "$HOME/.bashrc";
			(until test -n "$(tmux list-clients)"; do sleep 1; done; sleep 3; tmux display-message -t main "Run 'tmux detach' to exit from here") & disown;
			AWAIT_SHIM_PRINT_INDICATOR=true tmux a
			printf 'INFO: \n\n%s\n\n' "Spawning a debug bash shell";
			exec bash -l;
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

		docker "${docker_args[@]}" -c "$(printf "%s\n" "$(declare -f startup_command)" "startup_command")";
	}

)



