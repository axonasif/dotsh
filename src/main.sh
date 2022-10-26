use std::print::log;
use std::native::sleep;
# use std::sys::info::os;
use std::sys::info::distro;

use utils;
use install;
use config;
use variables;

function main() {

	# Logging
	if is::codespaces; then {
		local log_file="$HOME/.dotfiles.log";
		log::info "Manually redirecting dotfiles install.sh logs to $log_file";
		exec >> "$log_file";
		exec 2>&1;
	} fi

	# "& disown" means some sort of async

	# Dotfiles installation, symlinking files bascially
	install::dotfiles & disown;
	
	# Tmux + plugins + set as default shell for VSCode + create gitpod-tasks as tmux-windows
	config::tmux &

	# Shell + Fish hacks
	if is::gitpod || is::codespaces; then {
		config::shell::persist_history & disown;
		config::shell::fish::append_hist_from_gitpod_tasks & disown;
	} fi
	config::fish & disown;

	# Start installation of system(apt) packages
	if std::sys::info::distro::is_ubuntu; then {
		install::system_packages & disown;
	} fi

	# Install userland tools, some manually and some with nix
	install::userland_tools & disown;

	# Configure docker credentials
	if is::gitpod; then {
		config::docker_auth & disown;
	} fi

	# Configure neovim
	config::neovim & disown;
	
	# Install and login into gh
	config::gh & disown;

	# Ranger + plugins
	# install::ranger & disown;

	# Wait for "owned" background processess to exit
	# it will ignore "disown"ed commands as you can see up there.
	log::info "Waiting for background jobs to complete" && jobs -l;
	while test -n "$(jobs -p)" && sleep 0.2; do {
		printf '.';
		continue;
	} done

	log::info "Dotfiles script exited in ${SECONDS} seconds";
}
