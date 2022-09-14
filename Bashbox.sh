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
	rm -rf "$_arg_path/.private";
}

live() (
	local offline_dotfiles_repo="${DOTFILES_PRIMARY_REPO:-/workspace/dotfiles.public}";
	log::info "Using $offline_dotfiles_repo as the raw dotfiles repo";

	# if test "$1" == "r"; then {
		cmd="bashbox build --release";
		log::info "Running '$cmd";
		$cmd;
	# } fi

	local duplicate_workspace_root="/tmp/.mrroot";
	local duplicate_repo_root="$duplicate_workspace_root/${GITPOD_REPO_ROOT##*/}";

	log::info "Creating a clone of $GITPOD_REPO_ROOT at $duplicate_workspace_root" && {
		rm -rf "$duplicate_workspace_root";
		mkdir -p "$duplicate_workspace_root";
		cp -ra "$GITPOD_REPO_ROOT" /workspace/.gitpod "$duplicate_workspace_root";
	}

	local ide_mirror="/tmp/.idem";
	if test ! -e "$ide_mirror"; then {
		log::info "Creating /ide mirror";
		cp -ra /ide "$ide_mirror";
	} fi

	log::info "Starting a fake Gitpod workspace with headless IDE" && {
		local ide_cmd ide_port;
		ide_cmd="$(ps -p $(pgrep -f 'sh /ide/bin/gitpod-code' | head -n1) -o args --no-headers)";
		ide_port="33000";
		ide_cmd="${ide_cmd//23000/${ide_port}} >/ide/server_log 2>&1";

		local docker_args=(
			run
			--net=host

			# Shared mountpoints
			-v "$duplicate_workspace_root:/workspace"
			-v "$duplicate_workspace_root/${GITPOD_REPO_ROOT##*/}:$HOME/.dotfiles"
			-v "$ide_mirror:/ide"
			-v /usr/bin/gp:/usr/bin/gp:ro

			# Use offline dotfiles repo
			-e DOTFILES_PRIMARY_REPO="$offline_dotfiles_repo"
			-v "$offline_dotfiles_repo:$offline_dotfiles_repo"
			
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
			# Disable ssh:// protocol launch
			-e DOTFILES_SPAWN_SSH_PROTO=false

			# Container image
			-it gitpod/workspace-base:latest

			# Startup command
			/bin/sh -lic "eval \$(gp env -e); $ide_cmd & \$HOME/.dotfiles/install.sh; exec bash -l"
		)

		docker "${docker_args[@]}";
	}

)



