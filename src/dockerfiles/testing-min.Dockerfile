# Used for live testing (i.e 'bashbox live')
FROM gitpod/workspace-base:latest

ENV USER=gitpod

RUN curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon;

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \ 
	&& nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable \
	&& nix-channel --update;

RUN sudo sh -c 'f=/usr/bin/yq; curl -sSL https://github.com/mikefarah/yq/releases/download/v4.30.2/yq_linux_amd64 --output $f && chmod +x $f '