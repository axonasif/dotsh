# Used for live testing (i.e 'bashbox live')
FROM gitpod/workspace-base:latest

ENV USER=gitpod

RUN curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon;

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \ 
	&& nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable \
	&& nix-channel --update;

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
	&& nix-env -iA nixpkgs.fish nixpkgs.tmux nixpkgs.jq nixpkgs-unstable.neovim nixpkgs.gnumake;