use std::print::log;
use std::native::sleep;

use variables;
use utils;
use install;
use config;

function main() {
	# "& disown" means some sort of async

    # Start installation of system(apt) packages (async)
    install::system_packages & disown;

    # Dotfiles installation (blocking - sync)
    {
        
        local _private_dir="$source_dir/.private"; # Path to private dotfiles directory
        # You can set PRIVATE_DOTFILES_REPO with */* scope in https://gitpod.io/variables for your personal dotfiles
        local _private_dotfiles_repo="${PRIVATE_DOTFILES_REPO:-}"; # This is a git URL

        # Local dotfiles from this repository
        log::info "Installing local dotfiles";
        install::dotfiles "$___self_REPOSITORY" "$source_dir/raw";

        # Private dotfiles
		if test -n "$_private_dotfiles_repo"; then {
			log::info "Installing private dotfiles";
			install::dotfiles "${PRIVATE_DOTFILES_REPO:-"$_private_dotfiles_repo"}" "$_private_dir" || :;
		} fi
    }

    # Install userland tools
    install::userland_tools & disown;

    if is::gitpod; then {
        log::info "Gitpod environment detected!";
        
        # Configure docker credentials
        config::docker_auth & disown;

        # Shell + Fish hacks (specific to Gitpod)
        config::shell::persist_history;
        config::shell::fish::append_hist_from_gitpod_tasks &
		# config::shell::bash::gitpod_start_tmux_on_start &
        config::shell::hijack_gitpod_task_terminals &
		
		# Tmux + plugins + set as default shell for VSCode
		install::tmux &
		config::shell::vscode::set_tmux_as_default_shell & disown;

        # Configure neovim
        config::neovim & disown;
		
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
