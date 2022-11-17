function config::scm_cli() {
	local tarball_url gp_credentials;

	# Wait for gh to be installed via nix at userland_tools.sh:leveltwo_pkgs
	await::until_true command::exists gh;

	# Login into scm_cli (i.e. gh or glab)
	await::for_vscode_ide_start;

	declare -a scm_cli_args=("${gitpod_scm_cli}" auth login);
  declare scm_host;
	case "$gitpod_scm_cli" in
		"gh")
			scm_cli_args+=(
				--with-token
			)
      scm_host="github.com";
		;;
		"glab")
			scm_cli_args+=(
				--stdin
			)
      scm_host="gitlab.com";
		;;
	esac

	# if [[ "$(printf '%s\n' host=github.com | gp credential-helper get)" =~ password=(.*) ]]; then {
	local token && if token="$(printf '%s\n' host=github.com | gp credential-helper get | awk -F'password=' '{print $2}')"; then {
		# local token="${BASH_REMATCH[1]}";
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
		log::error "Failed to get auth token for gh" || exit 1;
	} fi
}
