function install::userland_tools {
    log::info "Installing userland tools";

	### Just put all sorts of commands one by one here.

	# Install bashbox
	(
		curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s -- selfinstall --no-modify-path >/dev/null 2>&1;
		
		if test -e "$HOME/.bashrc.d"; then {
			: ".bashrc.d";
		} elif test -e "$HOME/.shellrc.d"; then {
			: ".shellrc.d";
		} else {
			exit 0;
		} fi
		printf 'source %s\n' "$HOME/.bashbox/env" > "$HOME/$_/bashbox.bash";

	) & disown;

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
		if std::sys::info::distro::is_ubuntu; then {
			local levelone_pkgs=();
		} else {
			local levelone_pkgs=(
				tmux
				fish
				jq
			)
		} fi

		local leveltwo_pkgs=(
			lsof
			shellcheck
			# rsync
			tree
			file
			fzf
			# bash
			bat
			bottom
			# coreutils
			exa
			# ffmpeg
			# fish
			fzf
			# gawk
			gh
			# htop
			# iftop
			# jq
			neofetch
			neovim
			p7zip
			# ranger
			# reattach-to-user-namespace
			ripgrep
			shellcheck
			tree
			# yq
			jq
			zoxide
			# zsh
		)
		# return # DEBUG
		for level in levelone_pkgs leveltwo_pkgs; do {
			declare -n ref="$level";
			if test -n "${ref:-}"; then {
				nix-env -f channel:nixpkgs-unstable -iA "${ref[@]}" >/dev/null 2>&1
			} fi
		} done
	) & disown;
}
