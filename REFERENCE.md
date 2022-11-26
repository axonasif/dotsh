Note: this page can be outdated, please refer to [./src/variables.sh](./src/variables.sh) instead.

# Configuration

If it's your first time using dotsh, you can go through an interactive configuration wizard by running `dotsh config`.

You can customize the hookable options from [./src/variables.sh](./src/variables.sh).

The UPPERCASE variables inside [./src/variables.sh](./src/variables.sh) can be supplied as environment variables as well when needed. That means, for Gitpod you can define them at https://gitpod.io/variables with */* scope and for a local machine, you could do: `export KEY=value` once before executing `install.sh` per session. When exported as environment variables, they will overwrite the static values from your [./src/variables.sh](./src/variables.sh) during runtime.

# Guides

## Open `ssh://` protocol URLs in local terminal emulator

I have only tried this with Kitty and iTerm2, they have built-in capabilities for handling custom protocols. However, it's possible to accomplish the same using a shell-script for terminals lacking built-in handling, but we're not going to get into that here. 

#### iTerm2

- Open iTerm2.
- From the top right macOS menubar, go to **iTerm2 > Preferences > Profiles > Default (or a custom profile)**.
- Select `ssh` from the **URL Schemes** drop-down option.
- Close the **Preferences** window.

Official documentation: https://iterm2.com/documentation-one-page.html

#### Kitty

Kitty by default can handle `ssh` protocol. However, on MacOS you would need to register it into the system manually.

See https://sw.kovidgoyal.net/kitty/open_actions/#scripting-the-opening-of-files-with-kitty-on-macos for instructions.

## Handle automatic port forwarding on your SSH tmux session protocol.

You can use one of the following:

- https://www.gitpod.io/docs/references/ides-and-editors/local-companion - runs in the background (recommended)
- Or this: https://github.com/axonasif/gssh - Wraps the `ssh` command.
> If you wish to use `gssh` with iTerm/Kitty `ssh://` handling, you will need to pass the full `$$URL$$` in a custom command that runs: `gssh <URL>`.

## Extend `dotsh` with your own functions

Dotsh is programmed in plain `bash` and is compiled with [bashbox](https://github.com/bashbox/bashbox). 

Check [./src/config/example.sh](./src/config/example.sh) for example instructions.

# Helper functions

Note: There are more, check the source code instead, mainly the [./src/utils/](./src/utils/) directory and [std](https://github.com/bashbox/std).

## [vscode::add_settings](https://github.com/axonasif/dotfiles/blob/main/src/utils/common.sh#L6)

This let's you easily add settings to the Gitpod workspace VSCode instance. Settings added via this function will not be synced and is scoped to the applied workspaces only.

Usage example:

- Via stdin:

```bash
vscode::add_settings /path/to/settings.json <<-'JSON'
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

Live usage example can be seen [here](https://github.com/axonasif/dotfiles-sh/blob/main/src/config/tmux.sh#L238).

- Via file:

```bash
vscode::add_settings /path/to/settings.json < /path/to/source_file.json
```

## [dotfiles::initialize](https://github.com/axonasif/dotfiles-sh/blob/main/src/utils/common.sh#L52)

Automatically clone and symlink from a remote `dotfiles` repository tree. It also cleans up broken symlinks from previous apply (useful when used on local PC). You can ignore symlinking files by specifying their paths on a [`.dotfilesignore`](https://github.com/axonasif/dotfiles.public/blob/main/.dotfilesignore) on the repo root of your dotfiles raw tree.

Usage:

```js
REPO="your-repo-link/path-here" dotfiles::initialize [target-dir]
```

`REPO=` accepts URL or local path. (Defaults to https://github.com/axonasif/dotfiles.public)

`REPO=` and `target-dir` is optional.

`target-dir` is the directory/folder where symlinks will be applied from the cloned repo. (Defaults to `$HOME`)

If you wish to apply the symlinks to a different directory for example:

```js
REPO="your-repo-link/path-here" dotfiles::initialize "/root/.local/very/deep/location";
```

Live examples of it's usage can be found on this [file](/src/install/dotfiles.sh)

## [await::until_true](https://github.com/axonasif/dotfiles-sh/blob/main/src/utils/await.sh#L1)

```js
await::until_true <cmd>;
```

Simple wrapper for awaiting a command to return `true`

Live usage example can be found [here](https://github.com/axonasif/dotfiles-sh/blob/main/src/config/tmux.sh#L296).

## [await::for_file_existence](https://github.com/axonasif/dotfiles-sh/blob/main/src/utils/await.sh#L9)

```js
await::for_file_existence <file_path>;
```

Await for a file to appear in the filesystem.

Live usage example can be found [here](https://github.com/axonasif/dotfiles-sh/blob/main/src/utils/common.sh#L36).

## [await::for_vscode_ide_start](https://github.com/axonasif/dotfiles-sh/blob/main/src/utils/await.sh#L14)

```js
await::for_vscode_ide_start;
```

Await for the Gitpod VSCode window to appear.

Live usage example can be found [here](https://github.com/axonasif/dotfiles-sh/blob/main/src/install/gh.sh#L11).

## [await::create_shim](https://github.com/axonasif/dotfiles-sh/blob/main/src/utils/await.sh#L37) (Unstable)

```js
await::create_shim /usr/bin/something_fancy
```

### Problem 1

---

Let's say we're intalling a tool called `tmux` but since it's asynchronously installed so if an user tries to execute it before it exists, they'll get an error. In order to avoid such a problem we can place an wrapper script at `tmux`'s absolute path using `await::create_shim`, that way the wrapper script as `tmux` will await for the actual command to appear in the filesystem and switch(`exec`) to it if someone executes `tmux` on their terminal before the actual `tmux` binary/program gets fully installed. In other words, if you invoke `tmux` on your terminal, the wrapper script at `/usr/bin/tmux` will `sleep()` until it finds that it itself was overwritten and the actual `tmux` binary was installed at `/usr/bin/tmux`.

Now, there is another problem, let's say you used `await::create_shim /usr/bin/tmux` while `tmux` is being installed in the background asynchronously. What if you also need to install/configure additional `tmux` plguins/customizations from your dotfiles installation script but the _user_ tried to run `tmux` before you installed the additional customization. In this case, `tmux` would start up without your customization during the process you may perform the customizations in the background. There is a solution to that. Here's an example below:

```bash
# Install tmux asynchronously in the background
sudo apt install tmux & disown;

# Create the awaiting shim for any user execution before apt fully installs tmux, notice the extra `KEEP=true`
KEEP=true await::create_shim /usr/bin/tmux;

## Extra tmux customization/configuration part
git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm";
# This script has to execute `tmux` internally multiple times
# But we need it to hit the actual tmux binary but not the wrapper shim script,
# however the wrapper shim script will recognize that it's being called from inside the dotfiles installation script
# and thus it will let us to execute the actual binary of `tmux`
bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh";

# After we're done customizing internally, get rid of the wrapper shim script
# and let everyone directly hit the actual `tmux` binary.
CLOSE=true await::create_shim /usr/bin/tmux;
```

A live usage of `KEEP=true await::create_shim` can be seen [here](https://github.com/axonasif/dotfiles-sh/blob/main/src/config/tmux.sh#L250).

### Problem 2

---

What if you want to install `tmux` with a much complicated package manager such as `nix` for example and that you have to install `nix` first. Well, in that case, if you create the placeholder dirs and the shim before installation of `nix` and the package that you want to install, then it will cause issues during installation of `nix` and the packages that you want to install via it afterwards. So, we can create a shim in a different PATH, which will monitor another path to swap itself with. Here's an example:

```bash

# Install nix if missing
USER="$(id -u -n)" && export USER;
if test ! -e /nix; then {
  sudo sh -c "mkdir -p /nix && chown -R $USER:$USER /nix";
  log::info "Installing nix";
  curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon >/dev/null 2>&1;
} fi
source "$HOME/.nix-profile/etc/profile.d/nix.sh" || source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh;

# Install packages with nix in the background
# This command will eventually install a symlink to `tmux` at $HOME/.nix-profile/bin
nix-env -iA nixpkgs.tmux & disown;

# Notice the SHIM_MIRROR value
KEEP=true SHIM_MIRROR=$HOME/.nix-profile/bin/tmux await::create_shim /usr/bin/tmux;

## Extra tmux customization/configuration part
git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm";
# Install tmux plugins
bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh";

# After we're done customizing internally, get rid of the wrapper shim script
# and let everyone directly hit the actual `tmux` binary.
CLOSE=true await::create_shim /usr/bin/tmux;
```

## [await::signal](https://github.com/axonasif/dotfiles-sh/blob/main/src/utils/await.sh#L20)

Let's you await between multiple async commands.

Example:

In function `foo` we have:

```bash
function foo() {
    await::signal get boo_is_cool; # Blocks execution until signal is received

    echo "Now we can proceeed!";

    # More commands below...
}
```

In function `boo` we have:

```bash
function boo() {
    # Let's run some random commands
    sudo apt install shellcheck;

    await::signal send boo_is_cool; # Sends the singal to any awaiting client so that they can continue execution
}
```
