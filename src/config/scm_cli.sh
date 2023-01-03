function config::scm_cli() {

    local token;

    # Wait for gh to be installed via nix at userland_tools.sh:leveltwo_pkgs
    await::until_true command::exists "${gitpod_scm_cli}";
    await::for_gitpod_workspace_ready;

    # Login into scm_cli (i.e. gh or glab)
    declare -a scm_cli_args=("${gitpod_scm_cli}" auth login);
    declare scm_host;
    case "$gitpod_scm_cli" in
        "gh")
            scm_cli_args+=(
                --with-token
            )
            token="${DOTFILES_GITHUB_TOKEN:-}";
            scm_host="github.com";
        ;;
        "glab")
            scm_cli_args+=(
                --stdin
            )
            token="${DOTFILES_GITLAB_TOKEN:-}";
            scm_host="gitlab.com";
        ;;
    esac

    # if [[ "$(printf '%s\n' host=github.com | gp credential-helper get)" =~ password=(.*) ]]; then {
    if test -n "${token:-}" || token="$(printf '%s\n' "host=${scm_host}" | gp credential-helper get | awk -F'password=' '{print $2}')"; then {
        local tries=1;
        until printf '%s\n' "$token" | "${scm_cli_args[@]}"; do {
            if test $tries -gt 2; then {
                log::error "Failed to authenticate to 'gh' CLI with 'gp' credentials after trying for $tries times with ${token:0:9}" 1 || exit;
                break;
            } fi
            ((tries++));
            sleep 1;
            continue;
        } done
    } else {
        log::error "Failed to get auth token for ${gitpod_scm_cli}" 1 || return;
    } fi
}
