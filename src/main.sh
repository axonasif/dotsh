use std::print::log;
use std::native::sleep;
use std::async::lockfile;
# use std::sys::info::os;
use std::sys::info::distro;

use utils;
use install;
use config;
use variables;

function main() {

	# Special logging case
	if is::codespaces; then {
		local log_file="$HOME/.dotfiles.log";
		log::info "Manually redirecting dotfiles install.sh logs to $log_file";
		exec >> "$log_file";
		exec 2>&1;
	} fi

	#### "& disown" means some sort of async :P

	# Dotfiles installation, symlinking files bascially
	install::dotfiles & disown;
	
	# Tmux + plugins + set as default shell for VSCode + create gitpod-tasks as tmux-windows
	config::tmux &
	config::fish & disown;

	# Start installation of system(apt) + userland(nix) packages + misc. things
	install::packages & disown;
	install::misc & disown;

	# Shell + Fish hacks
	if is::cde; then {
		config::shell::persist_history & disown;
		config::shell::set_default_vscode_profile & disown;
	} fi

	if is::gitpod; then {
		# Configure docker credentials
		config::docker_auth & disown;
		# Install and login into gh
		config::gh & disown;
		# Shell + Fish hacks
		config::shell::fish::append_hist_from_gitpod_tasks & disown;
	} fi

	# Configure neovim
	config::neovim & disown;
	
	# Ranger + plugins
	# install::ranger & disown;

	# Wait for "owned" background processess to exit (i.e. processess that were not "disown"ed)
	# it will ignore "disown"ed commands as you can see up there.
	log::info "Waiting for background jobs to complete" && jobs -l;
	while test -n "$(jobs -p)" && sleep 0.2; do {
		printf '.';
		continue;
	} done

	log::info "Dotfiles script exited in ${SECONDS} seconds";
}
