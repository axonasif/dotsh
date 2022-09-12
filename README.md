# Introduction

This is a wannabe dotfiles _framework_ intended for use on Gitpod and locally.

Highlights:
- Dotfiles `install.sh` executes in **under 1 seconds**, thus your IDE starts quick nomatter how many things you configure/install.
- Tight integration with `tmux` (replaces Gitpod tasks and VSCode terminal-UI), optimized for plain SSH based workflow.
  - Launch gitpod workspaces automatically inside a [local terminal emulator via `ssh://`](#how-to-automatically-launch-gitpod-workspaces-inside-your-local-terminal-emulator) to skip all the manual steps to SSH from your terminal emulator (i.e manually copying the ssh command and running it on the terminal).
- This repo features **[live testing of dotfiles](#how-to-live-test-changes)** within your existing Gitpod workspace itself so that you can prototype quickly.
- Works both locally and on Gitpod.
- Uses your favorite shell on Gitpod task-terminals while perseving bash/posix compatibility with the task scripts.


# How to use on Gitpod

Feel free to create your `dotfiles` by forking this repo!
You can then use it on https://gitpod.io/preferences for Gitpod.

Learn more about using dotfiles on Gitpod at https://www.gitpod.io/docs/config-dotfiles

# How it works on Gitpod

A brief overview:
```markdown
├── Gitpod clones this dotfiles repo and executes `install.sh` from $HOME/.dotfiles
│   ├── Asynchronously executes instructions inside `install.sh`
│   │   ├── Installs some system/userland packages
│   │   ├── Creates symlinks from this repo to `$HOME/` while following `.dotfilesignore` via a helper function
│   │   ├── Installs CLIs such as `gh`, `gcloud` and auto-logins into them along several other tools
│   │   ├── Process Gitpod workspace persisted shell histories
|   |   ├── Takes over how Gitpod starts the task-terminals and replaces them with `tmux` windows instead
├── Gitpod starts the IDE process
└── Logs are saved to $HOME/.dotfiles.log
```

# Customizing

Ideally it should be easy to understand and customize this repo since I tried my best to make the code very modular and self-explanatory. Take a look inside the entrypoint [`/src/main.sh`](./src/main.sh) to tweak stuff as per your needs, such as commenting out any function on [`/src/main.sh`](./src/main.sh) to disable that particular thing.

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

And it will test out your new dotfiles changes inside the existing workspace without affecting it. Sounds fun, right!?

## How to automatically launch Gitpod workspaces inside your local terminal emulator

As you may already know, Gitpod will automatically launch your [Desktop-VSCode](https://www.gitpod.io/docs/ides-and-editors/vscode) for you if you selected to use it. However that's not the case for plain SSH based workflow yet (Related: https://github.com/gitpod-io/gitpod/issues/9323).

Although, since Gitpod is pretty scriptable and modular, it's possible to handle this ourselves until this has been polished out in the Gitpod side.

TBD, more to write here....

## How to handle automatic port forwarding in on your SSH tmux session

TBD...

## Tweak behavior via environment variables

For Gitpod, you can set these on https://gitpod.io/variables with `*/*` as the scope.

Currently there are a few variables which can alter the behavior of my dotfiles:
### `DOTFILES_NO_VSCODE`
> Defaults to `false`.
> Setting this to `true` will cause it to kill VSCode so that you can claim back your memory and CPU usage 😜
----
### `DOTFILES_SPAWN_SSH_PROTO`
> Defaults to `true`.
> Setting this to `false` will cause it to skip launching your local terminal emulator via the `ssh://` protocol.
----
### `DOTFILES_DEFAULT_SHELL`
> Defaults to `/usr/bin/fish` (this is planned, not implemented yet).
> This is the shell that our `tmux` session will use.

## Helper functions

### [vscode::add_settings](https://github.com/axonasif/dotfiles/blob/d86ce10be9cd08ff2911f09e7eff71449bdd2090/src/utils/common.sh#L6)

This let's you easily add settings to the Gitpod workspace VSCode instance.

Usage example:

- Via stdin:

```bash
vscode::add_settings <<-'JSON'
{
	"terminal.integrated.profiles.linux": {
		"tmuxshell": {
			"path": "bash",
			"args": [
				"-c",
				"tmux new-session -ds main 2>/dev/null || :; if cpids=$(tmux list-clients -t main -F '#{client_pid}'); then for cpid in $cpids; do [ $(ps -o ppid= -p $cpid)x == ${PPID}x ] && exec tmux new-window -n \"vs:${PWD##*/}\" -t main; done; fi; exec tmux attach -t main"
			]
		}
	},
	"terminal.integrated.defaultProfile.linux": "tmuxshell"
}
JSON
```

- Via file:

> ```bash
> vscode::add_settings /path/to/file.json
> ```
