_system_packages=(
    tmux
	fish
	jq
    shellcheck
    rsync
    tree
	file
)

function install::system_packages {
    log::info "Installing system packages";
	{ 
		sudo apt-get update;
		sudo debconf-set-selections <<<'debconf debconf/frontend select Noninteractive';
		sudo apt-get install -yq --no-install-recommends "${_system_packages[@]}";
		sudo debconf-set-selections <<<'debconf debconf/frontend select Readline';
	} 1>/dev/null
}
