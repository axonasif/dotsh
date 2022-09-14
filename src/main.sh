use std::print::log;
use std::native::sleep;

use variables;
use utils;
use install;
use config;

function main() {
	# "& disown" means some sort of async

	# Dotfiles installation, symlinking files bascially
	install::dotfiles & disown;
	
	if is::gitpod; then {
		log::info "Gitpod environment detected!";
	
		# Start installation of system(apt) packages (async)
		install::system_packages & disown;

		# Install userland tools
		install::userland_tools & disown;

		# Configure docker credentials
		config::docker_auth & disown;

		# Shell + Fish hacks (specific to Gitpod)
		config::shell::persist_history;
		config::shell::fish::append_hist_from_gitpod_tasks & disown;

		config::fish & disown;
		
		# Tmux + plugins + set as default shell for VSCode + create gitpod-tasks as tmux-windows
		config::tmux & disown;

		# Configure neovim
		install::neovim & disown;
		
		# Install and login into gh
		install::gh & disown;
	} fi

	# Ranger + plugins
	install::ranger & disown;

	# Wait for "owned" background processess to exit
	# it will ignore "disown"ed commands as you can see up there.
	log::info "Waiting for background jobs to complete" && jobs -l;
	while test -n "$(jobs -p)" && sleep 0.2; do {
		printf '.';
		continue;
	} done

	log::info "Dotfiles script exited in ${SECONDS} seconds";
}
