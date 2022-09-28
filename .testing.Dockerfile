FROM gitpod/workspace-base:latest

ENV USER=gitpod

RUN curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon;