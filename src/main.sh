use std::print::log;
use std::native::sleep;
use std::async::lockfile;
use std::sys::info::os;
use std::sys::info::distro;
use std::process::preserve_sudo;

use utils;
use install;
use config;
use variables;

function main() {
	# Ensure and preserve sudo when not CDE
	if ! is::cde; then {
		process::preserve_sudo;
	} fi

	# Special logging case
	if is::codespaces; then {
		local log_file="$HOME/.dotfiles.log";
		log::info "Manually redirecting dotfiles install.sh logs to $log_file";
		exec >> "$log_file";
		exec 2>&1;
	} fi

	#### "& disown" means some sort of async :P

	# Start installation of system(apt) + userland(nix) packages + misc. things
	install::packages; # Spawns subprocesses internally as needed, dependant on OS.
	install::misc & disown;

	# Dotfiles installation, symlinking files bascially
	install::dotfiles & disown;

	# Sync local + global files
	install::filesync & disown;
	
	# Tmux + plugins + set as default shell for VSCode + create gitpod-tasks as tmux-windows
	config::tmux &

	# Shell + Fish hacks
	if is::cde; then {
		config::shell &
	} fi

	if is::gitpod; then {
		# Install and login into gh
		config::scm_cli & disown;
	} fi

	# Configure neovim
	config::editor & disown;
	
	# Ranger + plugins
	# install::ranger & disown;

	# Wait for "owned" background processess to exit (i.e. processess that were not "disown"ed)
	# it will ignore "disown"ed commands as you can see up there.
	log::info "Waiting for background jobs to complete" && jobs -l;
	while test -n "$(jobs -rp)" && sleep 0.2; do {
		printf '.';
		continue;
	} done

	log::info "Dotfiles script exited in ${SECONDS} seconds";
}
