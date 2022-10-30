function config::gh() {
	local tarball_url gp_credentials;

	# Wait for gh to be installed via nix at userland_tools.sh:leveltwo_pkgs
	await::until_true command -v gh 1>/dev/null;

	# Login into gh
	await::for_vscode_ide_start;
	if [[ "$(printf '%s\n' host=github.com | gp credential-helper get)" =~ password=(.*) ]]; then {
		local token="${BASH_REMATCH[1]}";
		local tries=1;
		until printf '%s\n' "$token" | gh auth login --with-token >/dev/null 2>&1; do {
			if test $tries -gt 5; then {
				log::error "Failed to authenticate to 'gh' CLI with 'gp' credentials after trying for $tries times with ${token:0:12}" 1 || exit;
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