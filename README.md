# README is outdated

# Introduction

This is a wannabe dotfiles _framework_ intended for use on Gitpod and locally.

Highlights:
- Dotfiles `install.sh` executes in **under 1 seconds**, thus your IDE starts quick nomatter how many things you configure/install.
- Tight integration with `tmux` (replaces Gitpod tasks and VSCode terminal-UI), optimized for plain SSH+Neovim setup.
- This repo features **live testing of dotfiles** within your existing Gitpod workspace itself so that you can prototype quickly.
- Works both locally and on Gitpod.


# How to use on Gitpod

Feel free to create your `dotfiles` by forking this repo!
You can then use it on https://gitpod.io/preferences for Gitpod.

You can learn more about using dotfiles on Gitpod at https://www.gitpod.io/docs/config-dotfiles

# How it works on Gitpod
```markdown
├── Gitpod clones this dotfiles repo and executes `install.sh` from $HOME/.dotfiles
│   ├── Asynchronously executes instructions inside `install.sh`
│   │   ├── Installs some system/userland packages
│   │   ├── Creates symlinks from this repo to `$HOME/` while following `.dotfilesignore` via a helper function
│   │   ├── Installs CLIs such as `gh`, `gcloud` and auto-logins
│   │   ├── Process Gitpod workspace persisted shell histories
|   |   ├── Takes over how Gitpod starts the task-terminals and replaces them with `tmux` windows instead.
│   │   ├── Hacks `$HOME/.bashrc` to make Gitpod prebuild terminals fall back to fish shell after completion
├── Gitpod starts the VSCODE IDE
│   │   ├── Creates symlinks from $HOME/.dotfiles/.private to $HOME/ while following `.dotfilesignore` (If you provided PRIVATE_DOTFILES_REPO)
└── Logs are saved to $HOME/.dotfiles.log
```

# Customizing

Ideally it should be easy to understand and customize this repo since I tried my best to make the code very modular and self-explanatory. You can take a look inside the entrypoint [`/src/main.sh`](./src/main.sh) to tweak stuff as per your needs.

## How to compile

Run the following command:

```bash
bashbox build --release
```

## How to live test changes

I'm mimicking a minimal a process of how Gitpod starts a workpsace and initalizes dotfiles in it. This way we can quickly test out our dotfiles without having to:

1. commit+push the changes
2. create new workspaces each time after that

which was a very annoying and time consuming process.

There is a custom package script defined inside the [`Bashbox.sh`](./Bashbox.sh) called [`live`](https://github.com/axonasif/dotfiles/blob/main/Bashbox.sh#L23). You can execute it like so:

```bash
bashbox live
```

And it will test out your dotfiles inside the existing workspace without affecting it. Sounds fun, right!?



