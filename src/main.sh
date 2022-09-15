use std::print::log;
use std::native::sleep;
# use std::io::stdio;

use utils;
use install;
use config;
use variables;

function main() {
	# Logging

	# io::stdio::to_file /tmp/.dotfiles.stdout /tmp/.dotfiles.stderr;

	# "& disown" means some sort of async

	# Dotfiles installation, symlinking files bascially
	install::dotfiles & disown;
	
	if is::gitpod || is::codespaces; then {
		# Start installation of system(apt) packages (async)
		install::system_packages & disown;

		# Install userland tools, some manually and some with nix
		install::userland_tools & disown;

		# Configure docker credentials
		config::docker_auth & disown;

		# Shell + Fish hacks
		config::shell::persist_history;
		config::shell::fish::append_hist_from_gitpod_tasks & disown;
		config::fish & disown;

		# Tmux + plugins + set as default shell for VSCode + create gitpod-tasks as tmux-windows
		config::tmux & disown;

		# Configure neovim
		install::neovim & disown;
		
		# Install and login into gh
		install::gh & disown;

		# Ranger + plugins
		install::ranger & disown;
	} fi

	# Wait for "owned" background processess to exit
	# it will ignore "disown"ed commands as you can see up there.
	log::info "Waiting for background jobs to complete" && jobs -l;
	while test -n "$(jobs -p)" && sleep 0.2; do {
		printf '.';
		continue;
	} done

	log::info "Dotfiles script exited in ${SECONDS} seconds";
}
