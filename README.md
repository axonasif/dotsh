# Introduction

This is a wannabe dotfiles _framework_ intended for use on Gitpod and locally.

It does a few things to ease my life a bit:

- Works both locally and in the Cloud on Gitpod
- Installs this repo dotfiles and also puts another private dotfiles repo on top of it
    - Set `PRIVATE_DOTFILES_RPO` url on https://gitpod.io/variables with `*/*` scope to use it. Or if you're using locally, you can export the variable from your shell.
- Installs a bunch of handy system tools I use often.
- Persists Gitpod workspace shell(bash, fish, zsh etc) histories to the specific workspace on restart of a workspace.
- Makes `.gitpod.yml` task terminals to use `fish` shell after the commands are processed in bash, we can not make `fish` execute those task commands since it's not POSIX compliant.
- Makes `fish` shell properly inherit the `bash` specific environment variables and hooks, since almost all tools we install are injected by the bash profile, so any change to the bash profile is also reflected in your fish shell.
- GPG signing (Planned)
- You tell me!

You can take a look inside the `/src` dir to tweak stuff as per your needs and run `bashbox build --release` or `bashbox run --release`.

# How it works on Gitpod
```markdown
├── Gitpod clones your dotfiles repo and executes `install.sh` from $HOME/.dotfiles
│   ├── install.sh
│   │   ├── Installs some system packages with `apt` in the background
│   │   ├── Creates symlinks from this repo to $HOME/ while following `.dotfilesignore`
│   │   ├── Installs userland tools
│   │   ├── Process Gitpod workspace persisted shell histories
│   │   ├── Hacks `$HOME/.bashrc` to make Gitpod prebuild terminals fall back to fish shell after completion
├── Gitpod starts the VSCODE IDE
│   │   ├── Creates symlinks from $HOME/.dotfiles/.private to $HOME/ while following `.dotfilesignore` (If you provided PRIVATE_DOTFILES_REPO)
└── Logs are saved to $HOME/.dotfiles.log
```

# How to use

Feel free to create your `dotfiles` by forking this repo!
You can then use it on https://gitpod.io/preferences for Gitpod.

You can learn more about using dotfiles on Gitpod at https://www.gitpod.io/docs/config-dotfiles
