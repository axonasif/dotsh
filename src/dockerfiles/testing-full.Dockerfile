# Used for live testing (i.e 'bashbox livetest')
FROM gitpod/workspace-base:latest

ENV USER=gitpod

RUN curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon;

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \ 
	&& nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable \
	&& nix-channel --update;

RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
	&& nix-env -iA nixpkgs.tmux nixpkgs.fish;

COPY --chown=gitpod:gitpod .tmux_plugins.conf $HOME/.tmux.conf
RUN . "$HOME/.nix-profile/etc/profile.d/nix.sh" \
	&& git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" >/dev/null 2>&1 \
	&& bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" \
	&& nix-env --uninstall tmux && nix-collect-garbage -d || true;

RUN sudo sh -c 'f=/usr/bin/yq; curl -sSL https://github.com/mikefarah/yq/releases/download/v4.30.2/yq_linux_amd64 --output $f && chmod +x $f '