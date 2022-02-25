# Introduction

This is a wannabe dotfiles _framework_ intended for use on Gitpod and locally.

It does a few things to ease my life a bit:

- Works both locally and in the Cloud on Gitpod
- Installs this repo dotfiles and also puts another private dotfiles repo on top of it (git clone fails for private repo currently).
- Installs a bunch of handy system tools I use often.
- Persists Gitpod workspace shell(bash, fish, zsh etc) histories to the specific workspace on restart of a workspace.
- Makes `.gitpod.yml` task terminals to use `fish` shell after the commands are processed in bash, we can not make `fish` execute those task commands since it's not POSIX compliant.
- Makes `fish` shell properly inherit the `bash` specific environment variables and hooks, since almost all tools we install are injected by the bash profile, so any change to the bash profile is also reflected in your fish shell.
- GPG signing (Planned)
- You tell me!

You can take a look inside the `/src` dir to tweak stuff as per your needs and run `bashbox build --release` or `bashbox run --release`.

# Work process
```markdown
├── Gitpod clones and executes `install.sh` from $HOME/.dotfiles
│   ├── install.sh
│   │   ├── Symlinks from $HOME/.dotfiles to $HOME while following `.dotfilesignore`
│   │   ├── Symlinks from $HOME/.dotfiles/.private to $HOME while following `.dotfilesignore`
│   │   ├── Performs all the other tasks
└── Logs are saved to $HOME/.dotfiles.log
```