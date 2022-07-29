use std::print::log;
use std::native::sleep;
use dotfiles_symlink;
use utils;
use install;
use config;

function main() {

    # Start installation of system(apt) packages (background)
    install::system_packages &

    # Dotfiles installation
    {
        local _source_dir="$(readlink -f "$0")" && _source_dir="${_source_dir%/*}";
        local _private_dir="$_source_dir/.private";
        local _private_dotfiles_repo="https://github.com/axonasif/dotfiles.private";

        # Local dotfiles
        log::info "Installing local dotfiles";
        dotfiles_symlink;

        # Private dotfiles
        # Note: you can set PRIVATE_DOTFILES_REPO with */* scope in https://gitpod.io/variables for your personal dotfiles
        log::info "Installing private dotfiles";
        dotfiles_symlink "${PRIVATE_DOTFILES_REPO:-"$_private_dotfiles_repo"}" "$_private_dir" || :;
    }

    # Install userland tools (background)
    install::userland_tools & disown

    if is::gitpod; then {
        log::info "Gitpod environment detected!";
        
        # Configure docker credentials
        docker_auth & disown

        # Shell + Fish hacks (specific to Gitpod)
        shell::persist_history;
        fish::append_hist_from_gitpod_tasks &
		bash::gitpod_start_tmux_on_start &
        shell::hijack_gitpod_task_terminals &
    } fi

    # Ranger + plugins
    ranger::setup & disown

    # Tmux + plugins
    tmux::setup &

	# Install and login into gh
	gh::setup & disown;

    # Wait for background processess to exit
    if test -n "$(jobs -p)"; then {
        log::warn "Waiting for background jobs to complete";
    } fi
}
