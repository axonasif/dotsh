levelone_syspkgs=(
	tmux
	fish
	jq
	lsof
)


function install::system_packages {
    log::info "Installing system packages";
	{ 
		sudo apt-get update;
		sudo debconf-set-selections <<<'debconf debconf/frontend select Noninteractive';
		sudo apt-get install -yq --no-install-recommends "${levelone_syspkgs[@]}";
		sudo apt-get install -yq --no-install-recommends "${leveltwo_syspkgs[@]}";
		sudo debconf-set-selections <<<'debconf debconf/frontend select Readline';
	}
	#>/dev/null 2>&1
}
