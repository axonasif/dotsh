use std::print::log;
use std::native::sleep;
use std::async::lockfile;
use std::sys::info::os;
use std::sys::info::distro;
use std::process::preserve_sudo;
use std::string::trim;

use utils;
use install;
use config;
use variables;

function main() {

  # Hook CLIs
  if test "${___self##*/}" == "dotsh" || test -v DEBUG_DOTSH; then {

    if test -n "${1:-}"; then {
      dotsh::cli "$@";
      declare cli_func="${1}::cli";
      if declare -F "${cli_func}" 1>/dev/null; then {
          shift && "${cli_func}" "$@";
      } else {
        log::warn "Unkown subcommand: ${1}";
      } fi
    } fi

    exit 0;
  } fi

    # Ensure and preserve sudo when not CDE
    if ! is::cde; then {
        process::preserve_sudo;
    } fi

    #### "& disown" means some sort of async :P

    # Start installation of system(apt) + userland(nix) packages + misc. things
    # Spawns subprocesses internally as needed, dependant on OS.
    BCLR="$BBLUE" structlog install::packages;
    BCLR="$BCYAN" structlog install::misc & disown;

    # Dotfiles installation, symlinking files bascially
    BCLR="$WHITE" structlog install::dotfiles & disown;

    # Sync local + global files
    BCLR="$YELLOW" structlog install::filesync & disown;
    
    # Tmux + plugins + set as default shell for VSCode + create gitpod-tasks as tmux-windows
    BCLR="$BPURPLE" structlog config::tmux &

    # Shell + Fish hacks
    if is::cde; then {
        BCLR="$ORANGE" structlog config::shell &
    } fi

    if is::gitpod; then {
        # Install and login into gh
        structlog config::scm_cli & disown;

        # Install self shim
        structlog install::dotsh & disown;
    } fi

    # Configure neovim
    BCLR="$GRAY" structlog config::editor & disown;
    
    # Ranger + plugins
    # install::ranger & disown;

    # Wait for "owned" background processess to exit (i.e. processess that were not "disown"ed)
    # it will ignore "disown"ed commands as you can see up there.
    declare i=1;
    log::info "Waiting for background jobs to complete" && jobs -l;
    while test -n "$(jobs -rp)" && sleep 0.2; do {
        if test $i -gt 50; then
          printf '.';
        else
          ((i=i+1));
        fi
    } done

    log::info "Dotfiles script exited in ${SECONDS} seconds";
}
