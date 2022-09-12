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

Feel free to create your `dotfiles` by forking this repo! You can then use it on https://gitpod.io/preferences for Gitpod.

By default it will apply my raw dotfiles tree from https://github.com/axonasif/dotfiles.public

If you wish to use your own raw dotfiles tree, you can either set [DOTFILES_PRIMARY_REPO](https://github.com/axonasif/dotfiles-sh#dotfiles_primary_repo) or modify it [here](https://github.com/axonasif/dotfiles-sh/blob/main/src/install/dotfiles.sh).

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

Currently there are a few variables which can alter the behavior of `dotfiles-sh` on the fly:

### `DOTFILES_NO_VSCODE`

> Defaults to `false`.

> Setting this to `true` will cause it to kill VSCode so that you can claim back your memory and CPU usage 😜

---

### `DOTFILES_SPAWN_SSH_PROTO`

> Defaults to `true`.

> Setting this to `false` will cause it to skip launching your local terminal emulator via the `ssh://` protocol.

---

### `DOTFILES_PRIMARY_REPO`

> Defaults to https://github.com/axonasif/dotfiles.public

> Setting this will change the primary dotfiles tree that `dotfiles-sh` will apply on `$HOME`.

---

### `DOTFILES_DEFAULT_SHELL`

> Defaults to `/usr/bin/fish` (this is planned, not implemented yet).

> This is the shell that our `tmux` session will use.

## Helper functions

These are some functions that you can use if you wish to do some advanced customization on your own.

### [vscode::add_settings](https://github.com/axonasif/dotfiles/blob/d86ce10be9cd08ff2911f09e7eff71449bdd2090/src/utils/common.sh#L6)

This let's you easily add settings to the Gitpod workspace VSCode instance. Settings added via this function will not be synced and is scoped to the applied workspaces only.

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

Live usage example can be seen [here](https://github.com/axonasif/dotfiles-sh/blob/c998729e2a1adae908e897e503ebc3b4430e46b0/src/config/tmux.sh#L238).

- Via file:

```bash
vscode::add_settings /path/to/file.json
```

### [dotfiles::initialize](https://github.com/axonasif/dotfiles-sh/blob/c998729e2a1adae908e897e503ebc3b4430e46b0/src/utils/common.sh#L52)

Automatically clone and symlink from a remote `dotfiles` repository tree. It also cleans up broken symlinks from previous apply (useful when used on local PC)

Usage:

```js
REPO="your-repo-link-here" dotfiles::initialize [source-dir] [target-dir]
```

`source-dir` and `target-dir` is optional.

`source-dir` is where the repo will be cloned. (Defaults to `/tmp/.dotfiles_repo.${RANDOM}`)

`target-dir` is the directory/folder where symlinks will be applied from the cloned repo. (Defaults to `$HOME`)

If you wish to apply the symlinks to a different directory for example:

```js
REPO="your-repo-link-here" dotfiles::initialize "" "/root/.local/very/deep/location";
```

Live examples can be found on this [file](https://github.com/axonasif/dotfiles-sh/blob/main/src/install/dotfiles.sh)

### [wait::until_true](https://github.com/axonasif/dotfiles-sh/blob/c998729e2a1adae908e897e503ebc3b4430e46b0/src/utils/wait.sh#L1)

```js
wait::until_true <cmd>;
```

Simple wrapper for awaiting a command to return `true`

Live usage example can be found [here](https://github.com/axonasif/dotfiles-sh/blob/c998729e2a1adae908e897e503ebc3b4430e46b0/src/config/tmux.sh#L296).

### [wait::for_file_existence](https://github.com/axonasif/dotfiles-sh/blob/c998729e2a1adae908e897e503ebc3b4430e46b0/src/utils/wait.sh#L9)

```js
wait::for_file_existence <file_path>;
```

Await for a file to appear in the filesystem.

Live usage example can be found [here](https://github.com/axonasif/dotfiles-sh/blob/c998729e2a1adae908e897e503ebc3b4430e46b0/src/utils/common.sh#L36).

### [wait::for_vscode_ide_start](https://github.com/axonasif/dotfiles-sh/blob/c998729e2a1adae908e897e503ebc3b4430e46b0/src/utils/wait.sh#L14)

```js
wait::for_vscode_ide_start;
```

Await for the Gitpod VSCode window to appear.

Live usage example can be found [here](https://github.com/axonasif/dotfiles-sh/blob/c998729e2a1adae908e897e503ebc3b4430e46b0/src/install/gh.sh#L11).

More to write here...
