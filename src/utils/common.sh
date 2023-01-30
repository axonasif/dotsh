use libtmux::common;

function get::dotfiles-sh_dir() {
  if test -e "${GITPOD_REPO_ROOT:-}/src/variables.sh"; then {
    : "$GITPOD_REPO_ROOT";
  } elif test -e "$HOME/.dotfiles/src/variables.sh"; then {
    : "$HOME/.dotfiles";
  } else {
    log::error "Couldn't locate variables.sh" 1 || return;
  } fi

  printf '%s\n' "$_";
}

function is::gitpod() {
      # Check for existent of this gitpod-specific file and the ENV var.
      test -e /usr/bin/gp && test -v GITPOD_REPO_ROOT;
}

function is::codespaces() {
    test -v CODESPACES || test -e /home/codespaces;
}

function is::cde {
    is::gitpod || is::codespaces;
}

function try_sudo() {
    "$@" 2>/dev/null || sudo "$@";
}

function get::default_shell {

    await::signal get install_dotfiles;
    
    local custom_shell;
    if test "${DOTFILES_TMUX:-true}" == true; then {
        await::signal get config_tmux;
    } fi

    if test -n "${DOTFILES_SHELL:-}"; then {
        custom_shell="$(command -v "${DOTFILES_SHELL}")";

        if test "${DOTFILES_TMUX:-true}" == true; then {
            local tmux_shell;
            if tmux_shell="$(tmux::show-option default-shell)" \
            && [ "$tmux_shell" != "$custom_shell" ]; then {
                (
                    exec 1>&-;
                    until tmux has-session 2>/dev/null; do {
                        sleep 1;
                    } done
                    tmux set -g default-shell "$custom_shell" || :;
                ) & disown;
            } fi
        } fi

    } elif test "${DOTFILES_TMUX:-true}" == true; then {
        if custom_shell="$(tmux::show-option default-shell)" \
        && [ "${custom_shell}" == "/bin/sh" ]; then {
            custom_shell="$(command -v bash)";
        } fi

    } elif ! custom_shell="$(command -v fish)"; then {
        custom_shell="$(command -v bash)";
    } fi
    
    printf '%s\n' "${custom_shell:-/bin/bash}";
}

function command::exists() {
    declare cmd="$1" res;
    res="$(command -v "$cmd")" && test -x "$res";
}

# function wait::for_running_jobs() {
#     declare running_jobs && running_jobs=($(jobs -rp));
#     if test -n "${running_jobs:-}"; then {
#         wait "${running_jobs[@]}";
#     } fi
# }