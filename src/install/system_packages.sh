levelone_syspkgs=(
	# It is adviced to add very less packages in this array
	tmux
	fish
	jq
	
)

leveltwo_syspkgs=(
	# Add big packages in this array

)

function install::system_packages {

    log::info "Installing system packages";
	{ 
		sudo apt-get update;
		sudo debconf-set-selections <<<'debconf debconf/frontend select Noninteractive';
		for level in levelone_syspkgs leveltwo_syspkgs; do {
			declare -n ref="$level";
			if test -n "${ref:-}"; then {
				sudo apt-get install -yq --no-install-recommends "${ref[@]}";
			} fi
		} done
		sudo debconf-set-selections <<<'debconf debconf/frontend select Readline';
	} 1>/dev/null
}
