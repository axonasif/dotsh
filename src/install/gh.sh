function install::gh() {
	local tarball_url gp_credentials;

	# Install gh
	log::info "Installing gh CLI and logging in";
	tarball_url="$(curl -Ls "https://api.github.com/repos/cli/cli/releases/latest" \
		| grep -o 'https://github.com/.*/releases/download/.*/gh_.*linux_amd64.tar.gz')";
	curl -Ls "$tarball_url" | sudo tar -C /usr --strip-components=1 -xpzf -;

	# Login into gh
	await::for_vscode_ide_start;
	if token="$(printf '%s\n' host=github.com | gp credential-helper get | awk -F'password=' 'BEGIN{RS=""} {print $2}')"; then {
	# if [[ "$gp_credentials" =~ password=(.*) ]]; then {
		tries=1;
		until printf '%s\n' "${token}" | gh auth login --with-token &>/dev/null; do {
			if test $tries -gt 20; then {
				log::error "Failed to authenticate to 'gh' CLI with 'gp' credentials" 1 || exit;
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