# Used for live testing (i.e 'bashbox live')
FROM gitpod/workspace-base:latest

ENV USER=gitpod

RUN curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon;

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \ 
	&& nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable \
	&& nix-channel --update;

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
	&& nix-env -iA nixpkgs.fish nixpkgs.tmux nixpkgs.jq nixpkgs-unstable.neovim nixpkgs.gnumake;

COPY --chown=gitpod:gitpod .tmux_plugins.conf $HOME/.tmux.conf
RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
	&& git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" >/dev/null 2>&1 \
	&& bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" \
	&& curl -sL "https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh" | bash -s -- --no-install-dependencies -y;