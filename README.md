# Introduction

A fast dotfiles and system-configuration installer optimized for Gitpod (can be used locally too). Is this another dotfiles-manager? Nope. In fact, it will try to detect your dotfiles-manager and install your raw files through it if you're using one. This is essentially a script, it is meant to be modularly customized from source code and compiled for convenience. You can even call it a "framework" if you like 🙃

# Quickstart for Gitpod

Note: You will be using your existing dotfiles repo, `dotsh` is only the installer.

Open this repo on Gitpod:

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#github.com/axonasif/dotsh)

Then run `dotsh config` on a terminal for interactive configuration wizard.

Or if you just want to try it out:

- Put https://github.com/axonasif/dotsh on your **[Gitpod Preferences](https://gitpod.io/preferences) > Dotfiles**
- Later, you could customize it by running `dotsh config` if you want.

Learn more about dotfiles behaviour on Gitpod at https://www.gitpod.io/docs/config-dotfiles

# Quickstart for local machine

<details>
  <summary>Expand</summary>

Right now **only Linux and MacOS is supported**. In theory it could work on other \*nix systems and maybe Windows, that said, the script could run fine but some special handling of how things are installed or configured needs to be done for other systems, please contribute if you're an user of an "unsupported" system.

### Prerequisites

- git
- bash 4.3 or above

### Linux

Install `git` with your distro's package manager. Generally `bash` version is not an issue on Linux distros.

### MacOS

In MacOS you could install these via `brew` before proceeding.

```bash
# If you don't have homebrew already, otherwise skip this command
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

bash -lic 'set -m; brew install git bash'

exec bash -li # Reload bash
```

After you've made sure that the prerequisites are met, run:

```bash
# You may use your own fork instead
git clone https://github.com/axonasif/dotsh ~/.dotfiles
bash ~/.dotfiles/install.sh
```

</details>

# Features

Most of these features stemmed from my personal needs. Another reason was to avoid repetitive work while answering some frequent questions at the Gitpod Discord server that required manual handcrafting for each scenario, an unified ~~solution~~ workaround was needed. I simply couldn't wait but try implementing them myself as long it's possible within the context of `dotfiles` layer on Gitpod. I really like how programmable Gitpod can be unlike anything out there! (although I wish it was more obvious).

## Fast installation

https://user-images.githubusercontent.com/39482679/204036949-3ac297e1-33c7-41e5-9461-f504e5b16df5.mp4

The installation is highly parallelized. This leads to a reasonably fast Gitpod workspace startup. In the regular way it'd take at least 60seconds for my dotfiles installation itself, rendering dotfiles unusable. Some tricks are used to start fast without crashing things that rely on your custom-shell and tmux (for example) while they're being installed/configured in the background. One of the most important trick is lazy-loading binaries with (optional) locking.

<details>
  <summary>Extra details</summary>

### Lazy loading of binaries

A `bash` script is placed at an alternate place in `$PATH` or even the exact path of the real binary (where suitable) as a "shim". External programs (outside of `dotsh` process) will hit the "shim" and the "shim" will sleep until it receives a signal from `dotsh` (when necessary, otherwise no signals are required). This prevents the crash of programs that depends on a particular program. So for most of the cases, such dependant programs can get ahead of time with their tasks and only wait when necessary.

This is quite complicated under the hood due to race-conditions and filesystem operations, thankfully it didn't involve something like a fusefs implementaion which has it's own requirements (although that probably would've been easier to debug).

More details at [here](./REFERENCE.md#awaitcreate_shim-unstable)

</details>

Official issue: https://github.com/gitpod-io/gitpod/issues/7592

## Live testing of dotfiles and `.gitpod.yml`

https://user-images.githubusercontent.com/39482679/204037025-7747cf73-3204-43bc-a8a7-633c603861ad.mp4

Testing out `dotfiles` or `.gitpod.yml` changes can be a lengthy and difficult process (_something I have to do pretty much everyday_). This live testing capability allowed me to quickly prototype the rest of `dotsh` logic, which would've been quite impossible otherwise.

<details>
  <summary>Usage and details</summary>

### For only testing dotfiles changes:

**If you opened your `dotsh` repo on Gitpod**:

> Assuming your [CWD](https://en.wikipedia.org/wiki/Working_directory) is `/workspace/dotsh`, you can run `bashbox livetest`

**If you didn't open `dotsh` but a different repo and want to test your dotfiles**:

> - Go to `~/.dotfiles` (where `dotsh` gets cloned by Gitpod) by running `cd ~/.dotfiles`
> - Now run `bashbox livetest`
> Tip: You could also do `bashbox -C ~/.dotfiles livetest` if you do not want to `cd ~/.dotfiles`.

### For testing `.gitpod.yml` changes of a workspace (including dotfiles):

- Run `dotsh livetest` from anywhere in your workspace.

### Extra details

`livetest` command comes from [Bashbox.sh](./Bashbox.sh) as a package function. `dotsh livetest` command is an alias to `bashbox -C <dotfiles-dir> livetest ws`.

It shares almost everything from the host Gitpod workspace to the testing container, it may include:

- `/ide` (mirror, doesn't affect the original one)
- `/workspace` (ephemeral mirror, CoW via overlayfs)
- `/.supervisor` (direct bind mount)
- `/usr/bin/gp` (read-only)
- `/dev/fuse` (for things like `rclone mount`)
- `/var/run/docker.sock` (for using docker inside the testing container)
- dotfiles (mirror)
- Local network (to communicate with the IDE process, Gitpod API and expose ports to HOST)

This speeds up the process since we're just re-using the resources and is not expensive.

</details>

[Tmux integration](#tmux-integration) and the overall [quick feedback](#fast-installation) makes it much more useful.

**Note:** This is only optimized for Gitpod and will not work elsewhere. You can also try [run-gp](https://github.com/gitpod-io/run-gp) which also supports running a Gitpod workspace locally.

Official issue: https://github.com/gitpod-io/gitpod/issues/7671.

## Tmux integration

<p align="center"><img src="https://user-images.githubusercontent.com/39482679/203600977-327824cb-26a9-4802-821d-004363922f5b.png" alt="gitpod.tmux"></p>

Using SSH or terminal in general without TMUX feels powerless! Gitpod got amazing SSH support and various different ways to SSH into its workspaces.

[gitpod.tmux](https://github.com/axonasif/gitpod.tmux) plugin is auto-installed for you, and Gitpod tasks are opened inside tmux via `dotsh`.

`dotsh` pervents Gitpod tasks to be executed in the regular `bash` terminals and spawns them inside `tmux` windows. After the task completion in a POSIX friendly shell, it'll auto switch to your favorite shell.

### Integrated tmux usage from VSCode

VSCode is a great editor when you want to code from the browser, having an integrated tmux experience was must for me! All your new vscode terminals will get opened as tmux windows instead.

https://user-images.githubusercontent.com/39482679/204037099-854db4a9-430b-470f-9444-f3d1738446f8.mp4

## Cross-workspace and local filesync

File sync is a crutial feature when working with ephemeral workspaces. This let's you sync files across workspaces or locally to individual workspaces. That means you could persist your login for CLI programs, cache big files and so on. It's gluing together [rclone](https://github.com/rclone/rclone) to accomplish this, nothing special on it's own.

PS: This is easily one of the most wanted features on Gitpod.

<details>
  <summary>Usage</summary>

> Run `dotsh config rclone` for initial setup of `rclone` (if you haven't yet).

To start syncing files, you can use:

```bash
# This will save and restore in the absolute static path.
dotsh filesync save /path/to/file another_file
```

To save a file from your `$HOME` directory and to dynamically auto restore it based on user home dir:

```bash
# Useful when you're using dotsh both locally and on Gitpod.
# -dh is short form of --dynamic-home argument.
# I'm saving docker.json to persist my login, so that I don't have to login every time.
cd $HOME
dotsh filesync -dh .config/docker.json
```

### Why use `rclone`?

- It's cross-platform.
- Very powerful tool, has tons of options.
- You own your data and have the flexibility to decide where to host it.

</details>

Official issue: https://github.com/gitpod-io/gitpod/issues/9284

## Optimized for CLI EDITOR(s)

Your favorite CLI editor is quickly auto installed for you. Also several common CLI tools, dependencies, editor plugins/presets are install and configured based on your preference in ahead of time. So you can easily get started with your own editor-config without worrying about tweaking the system.

The following editors are supported:

- Emacs
- Helix
- NeoVim (I use this one)
- Vim

A popular editor-preset (e.g. LunarVim [awesome config BTW!], Spacemacs) is installed unless your own config is detected. You can customize this from [./src/variables.sh](./src/variables.sh#L81).

Official issue: https://github.com/gitpod-io/gitpod/issues/9323

## Optimized for custom SHELL(s)

You can use you favorite shell on Gitpod task-terminals while perseving bash/posix compatibility with the Gitpod task scripts and also the shell-environment. You don't have to sacrifice the usability of custom shells!

<details>
  <summary>Details</summary>

There is an _universal_ issue with shells like `fish` or `zsh`, most tools (e.g. cargo) provide shell-environment scripts that are POSIX or bash-compatible and usually installed for the system login-shell. I personally use `fish`, had to make a bit of efforts for dailydriving it everywhere as the interactive shell. In a local PC, what usually happens is that `fish` or `zsh` inherits the environment variables from the GUI terminal-emulator process, which are stemmed from the system zygote process spawning other (*GUI) applications on top of the login shell. This is also why you'd be asked to re-login (display-manager) or reboot after changing your shell from `chsh` on a traditional *unix system to reflect the changes.

### Fish

It will install [fisher](https://github.com/jorgebucaran/fisher) and install the following plugins via it:

- [axonasif/bashenv.fish](https://github.com/axonasif/bashenv.fish) (to use the env customizations of Gitpod and other tools from `bash`)
- [PatrickF1/fzf.fish](https://github.com/PatrickF1/fzf.fish) (for a powerful fzf integration)

You can modify this [here](/blob/ac7f1a9f00383d9cee8452bb32de7504b904dd31/src/variables.sh#L35).

### Zsh

The following are auto-installed:

- [axonasif/bashenv.zsh](https://github.com/axonasif/bashenv.zsh) (to use the env customizations of Gitpod and other tools from `bash`)
- [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh).

</details>

Official issue: https://github.com/gitpod-io/gitpod/issues/10105

## Easy SHH'ing through local terminal

https://user-images.githubusercontent.com/39482679/204090871-7abfb4b0-d757-40cb-ab0f-52f0ba5ccbd0.mp4

Launch gitpod workspaces automatically inside a [local terminal emulator via `ssh://`](./REFERENCE.md#open-ssh-protocol-urls-in-local-terminal-emulator) without having to copy-paste manually!

Official issue: https://github.com/gitpod-io/gitpod/issues/9323

## Easy cross-platform package installation

We need not to worry about package management and leave it on the shoulders of `nix`, which is a very powerful package manager, unlike any other! Oh and, it's cross-platform too with tons of packages. Since Gitpod workspaces are ephemeral, using `nix` is even easier!

With `dotsh`, `nix` package installations are chunked into different levels to optimize terminal readiness. To add your own packages, edit the `PACKAGES` section on [./src/variables.sh](./src/variables.sh#L81)

For example, here's how the level one packages array looks like on [./src/variables.sh](./src/variables.sh#L81):


```bash
declare nixpkgs_level_1+=(
    nixpkgs.ripgrep
    nixpkgs.fd
    nixpkgs.fzf
)
```

You can find packages at https://search.nixos.org/packages

## Host aware multi-layer dotfiles installation

It will not overwrite some crutial host files (e.g. `.bashrc`, `.gitconfig` and etc.) while installing your `dotfiles` repos but virtually load your ones to preserve integrity of the host system. (if you're using a custom dotfiles-manager like chezmoi, you need to handle it through your dotfiles-manager)

For more details on this and an example raw dotfiles tree, check [this](https://github.com/axonasif/dotfiles)

By default, it will use a basic symlinking mechanism unless you're using a dotfiles-manager, currently the following is recognized:

- chezmoi

## Extra goodies

- Auto login into `gh` or `glab` CLI based on your repository context.
- Shell completion for `gp` CLI.

# Contributing and development

Open this repo on Gitpod:

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#github.com/axonasif/dotsh)

And use the [livetesting](#live-testing-of-dotfiles-and-gitpodyml) mechanism for testing out your changes.

You can also run `bashbox build --release` for only compiling.

For viewing logs from the filesystem: `less -FXR ~/.dotfiles.log`

Also check [./REFERENCE.md](./REFERENCE.md)

# Back story

`dotsh` is basically a *pretty* accumulation of some of my scattered scripts that I had before, now it's just a bit more organized and meaningful. And also the fact that the Gitpod community bought me encouragement for putting this together. I didn't have a proper dotfiles setup before, it was a mess but it's also true that I've been iterating over my dotfiles for the last ~9 months 😝. If you found it useful, let me know! (you can find me hanging around at the [Gitpod Discord server](https://gitpod.io/chat))

I also personally hope that many of the things that I had to implement though Dotfiles would have an official and more robust implementation on Gitpod in the future! (Please react "👍" on the linked official issues BTW, that might help those getting prioritized)

This project was built with [bashbox](https://github.com/bashbox/bashbox), and it's following libraries:

- [std](https://github.com/bashbox/std)
- [libtmux](https://github.com/bashbox/libtmux)

Generally, bash scripts are error prone, hard to debug and maintain. But it changes with bashbox!
