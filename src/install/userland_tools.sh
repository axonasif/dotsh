function install::userland_tools {
    log::info "Installing userland tools";

	### Just put all sorts of commands one by one here.

	# Install bashbox
	curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall >/dev/null 2>&1 & disown;

	(
		# Install tools with nix
		USER="$(id -u -n)" && export USER;
		if test ! -e /nix; then {
			sudo sh -c "mkdir -p /nix && chown -R $USER:$USER /nix";
			log::info "Installing nix";
			curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon >/dev/null 2>&1;
		} fi
		source "$HOME/.nix-profile/etc/profile.d/nix.sh" || source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh;

		## You can find packages at https://search.nixos.org/packages
		local levelone_pkgs=(
			# Installing these from system_packages.sh for now
			# nixpkgs.tmux
			# nixpkgs.fish
			# nixpkgs.jq
		)
		local leveltwo_pkgs=(
			nixpkgs.lsof
			nixpkgs.shellcheck
			# nixpkgs.rsync
			nixpkgs.tree
			nixpkgs.file
			nixpkgs.fzf
			# nixpkgs.bash
			nixpkgs.bat
			nixpkgs.bottom
			# nixpkgs.coreutils
			nixpkgs.exa
			# nixpkgs.ffmpeg
			# nixpkgs.fish
			nixpkgs.fzf
			# nixpkgs.gawk
			nixpkgs.gh
			# nixpkgs.htop
			# nixpkgs.iftop
			# nixpkgs.jq
			nixpkgs.neofetch
			nixpkgs.neovim
			nixpkgs.p7zip
			# nixpkgs.ranger
			# nixpkgs.reattach-to-user-namespace
			nixpkgs.ripgrep
			nixpkgs.shellcheck
			nixpkgs.tree
			# nixpkgs.yq
			nixpkgs.jq
			nixpkgs.zoxide
			# nixpkgs.zsh
		)
		# return # DEBUG
		for level in levelone_pkgs leveltwo_pkgs; do {
			declare -n ref="$level";
			if test -n "${ref:-}"; then {
				nix-env -iA "${ref[@]}" >/dev/null 2>&1
			} fi
		} done
	) & disown;
}
