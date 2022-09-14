levelone_syspkgs=(
  tmux
	fish
	jq
	lsof
)
leveltwo_syspkgs=(
  hollywood
    shellcheck
    rsync
    tree
	file
	mosh
	fzf
)


function install::system_packages {
    log::info "Installing system packages";
	{ 
		sudo apt-get update;
		sudo debconf-set-selections <<<'debconf debconf/frontend select Noninteractive';
		sudo apt-get install -yq --no-install-recommends "${levelone_syspkgs[@]}";
		sudo apt-get install -yq --no-install-recommends "${leveltwo_syspkgs[@]}";
		sudo debconf-set-selections <<<'debconf debconf/frontend select Readline';
	} 1>/dev/null
}
