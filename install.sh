#!/usr/bin/env bash
main@bashbox%763 () 
{ 
    if test "${BASH_VERSINFO[0]}${BASH_VERSINFO[1]}" -lt 43; then
        { 
            printf 'error: %s\n' 'At least bash 4.3 is required to run this, please upgrade bash or use the correct interpreter' 1>&2;
            exit 1
        };
    fi;
    function process::self::exit () 
    { 
        local _r=$?;
        ( kill -USR1 "$___self_PID" 2> /dev/null || : ) & exit $_r
    };
    function process::self::forcekill () 
    { 
        kill -9 "$___self_PID" 2> /dev/null
    };
    function log::error () 
    { 
        local _retcode="${2:-$?}";
        local _exception_line="$1";
        local _source="${BB_ERR_SOURCE:-"${BASH_SOURCE[-1]}"}";
        if [[ ! "$_exception_line" == \(*\) ]]; then
            { 
                printf '[!!!] \033[1;31m%s\033[0m[%s]: %s\n' error "$_retcode" "${_source##*/}[${BASH_LINENO[0]}]: ${BB_ERR_MSG:-"$_exception_line"}" 1>&2;
                if test -v BB_ERR_MSG; then
                    { 
                        echo -e "STACK TRACE: (TOKEN: $_exception_line)" 1>&2;
                        local -i _frame=0;
                        local _treestack='|--';
                        local _line _caller _source;
                        while read -r _line _caller _source < <(caller "$_frame"); do
                            { 
                                printf '%s >> %s\n' "$_treestack ${_caller}" "${_source##*/}:${_line}" 1>&2;
                                _frame+=1;
                                _treestack+='--'
                            };
                        done
                    };
                fi
            };
        else
            { 
                printf '[!!!] \033[1;31m%s\033[0m[%s]: %s\n' error "$_retcode" "${_source##*/}[${BASH_LINENO[0]}]: SUBSHELL EXITED WITH NON-ZERO STATUS" 1>&2
            };
        fi;
        return "$_retcode"
    };
    \command unalias -a || exit;
    set -eEuT -o pipefail;
    shopt -s inherit_errexit expand_aliases;
    trap 'exit' USR1;
    trap 'BB_ERR_MSG="UNCAUGHT EXCEPTION" log::error "$BASH_COMMAND" || process::self::exit' ERR;
    ___self="$0";
    ___self_PID="$$";
    ___self_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)";
    ___MAIN_FUNCNAME='main@bashbox%763';
    ___self_NAME="dotfiles";
    ___self_CODENAME="dotfiles";
    ___self_AUTHORS=("AXON <axonasif@gmail.com>");
    ___self_VERSION="1.0";
    ___self_DEPENDENCIES=(std::HEAD);
    ___self_REPOSITORY="https://github.com/axonasif/dotfiles.git";
    ___self_BASHBOX_COMPAT="0.3.9~";
    function bashbox::build::after () 
    { 
        local _script_name='install.sh';
        local root_script="$_arg_path/$_script_name";
        cp "$_target_workfile" "$root_script";
        chmod +x "$root_script"
    };
    function live () 
    { 
        ( source "$_arg_path/src/utils/common.sh";
        rm -f "$_arg_path/.last_applied";
        local offline_dotfiles_repo="${_arg_path%/*}/dotfiles.public";
        if test -v DOTFILES_PRIMARY_REPO; then
            { 
                git clone "$DOTFILES_PRIMARY_REPO" "$offline_dotfiles_repo"
            };
        fi;
        log::info "Using $offline_dotfiles_repo as the raw dotfiles repo";
        cmd="bashbox build --release";
        log::info "Running '$cmd";
        $cmd;
        local duplicate_workspace_root="/tmp/.mrroot";
        local duplicate_repo_root="$duplicate_workspace_root/${_arg_path##*/}";
        log::info "Creating a clone of $_arg_path at $duplicate_workspace_root" && { 
            rm -rf "$duplicate_workspace_root";
            mkdir -p "$duplicate_workspace_root";
            cp -ra "$_arg_path" "$duplicate_workspace_root";
            if test -e /workspace/.gitpod; then
                { 
                    cp -ra /workspace/.gitpod "$duplicate_workspace_root"
                };
            fi
        };
        log::info "Starting a fake Gitpod workspace with headless IDE" && { 
            local docker_args=();
            docker_args+=(run --net=host);
            docker_args+=(-v "$duplicate_workspace_root:/workspace" -v "$duplicate_repo_root:$HOME/.dotfiles");
            if is::gitpod; then
                { 
                    docker_args+=(-v /usr/bin/gp:/usr/bin/gp:ro)
                };
            fi;
            docker_args+=(-e DOTFILES_PRIMARY_REPO="$offline_dotfiles_repo" -v "$offline_dotfiles_repo:$offline_dotfiles_repo");
            if is::gitpod; then
                { 
                    docker_args+=(-e GP_EXTERNAL_BROWSER -e GP_OPEN_EDITOR -e GP_PREVIEW_BROWSER -e GITPOD_ANALYTICS_SEGMENT_KEY -e GITPOD_ANALYTICS_WRITER -e GITPOD_CLI_APITOKEN -e GITPOD_GIT_USER_EMAIL -e GITPOD_GIT_USER_NAME -e GITPOD_HOST -e GITPOD_IDE_ALIAS -e GITPOD_INSTANCE_ID -e GITPOD_INTERVAL -e GITPOD_MEMORY -e GITPOD_OWNER_ID -e GITPOD_PREVENT_METADATA_ACCESS -e GITPOD_REPO_ROOT -e GITPOD_REPO_ROOTS -e GITPOD_THEIA_PORT -e GITPOD_WORKSPACE_CLASS -e GITPOD_WORKSPACE_CLUSTER_HOST -e GITPOD_WORKSPACE_CONTEXT -e GITPOD_WORKSPACE_CONTEXT_URL -e GITPOD_WORKSPACE_ID -e GITPOD_WORKSPACE_URL -e GITPOD_TASKS='[{"name":"Test foo","command":"echo This is fooooo"},{"name":"Test boo", "command":"echo This is boooo"}]' -e DOTFILES_SPAWN_SSH_PROTO=false)
                };
            fi;
            docker_args+=(-it gitpod/workspace-base:latest);
            if is::gitpod; then
                { 
                    docker_args+=(/bin/sh -lic "eval \$(gp env -e); \$HOME/.dotfiles/install.sh; exec bash -l")
                };
            else
                { 
                    docker_args+=(/bin/sh -lic '$HOME/.dotfiles/install.sh; exec bash -l')
                };
            fi;
            docker "${docker_args[@]}"
        } )
    };
    function log::info () 
    { 
        echo -e "[%%%] \033[1;37minfo\033[0m: $@"
    };
    function log::warn () 
    { 
        echo -e "[***] \033[1;37mwarn\033[0m: $@"
    };
    function sleep () 
    { 
        local IFS;
        [[ -n "${_snore_fd:-}" ]] || { 
            exec {_snore_fd}<> <(:)
        } 2> /dev/null || { 
            local fifo;
            fifo=$(mktemp -u);
            mkfifo -m 700 "$fifo";
            exec {_snore_fd}<> "$fifo";
            rm "$fifo"
        };
        read ${1:+-t "$1"} -u $_snore_fd || :
    };
    function is::gitpod () 
    { 
        test -e /usr/bin/gp && test -v GITPOD_REPO_ROOT
    };
    function is::codespaces () 
    { 
        test -v CODESPACES || test -e /home/codespaces
    };
    function vscode::add_settings () 
    { 
        local lockfile="/tmp/.vscs_add.lock";
        local vscode_machine_settings_file="${SETTINGS_TARGET:-$vscode_machine_settings_file}";
        trap "rm -f $lockfile" ERR SIGINT RETURN;
        while test -e "$lockfile" && sleep 0.2; do
            { 
                continue
            };
        done;
        touch "$lockfile";
        local input="${1:-}";
        if test ! -n "$input"; then
            { 
                read -t0.5 -u0 -r -d '' input || :
            };
        else
            if test -e "$input"; then
                { 
                    input="$(< "$input")"
                };
            else
                { 
                    log::error "$FUNCNAME: $input does not exist" || exit 1
                };
            fi;
        fi;
        if test -n "${input:-}"; then
            { 
                if test ! -e "$vscode_machine_settings_file"; then
                    { 
                        mkdir -p "${vscode_machine_settings_file%/*}";
                        touch "$vscode_machine_settings_file"
                    };
                fi;
                await::for_file_existence "/usr/bin/jq";
                if test ! -s "$vscode_machine_settings_file" || ! jq -reM '""' "$vscode_machine_settings_file" > /dev/null; then
                    { 
                        printf '%s\n' "$input" > "$vscode_machine_settings_file"
                    };
                else
                    { 
                        sed -i -e 's|,}|\n}|g' -e 's|, }|\n}|g' -e ':begin;$!N;s/,\n}/\n}/g;tbegin;P;D' "$vscode_machine_settings_file";
                        local tmp_file="${vscode_machine_settings_file%/*}/.tmp";
                        cp -a "$vscode_machine_settings_file" "$tmp_file";
                        jq -s '.[0] * .[1]' - "$tmp_file" <<< "$input" > "$vscode_machine_settings_file"
                    };
                fi
            };
        fi
    };
    function dotfiles::initialize () 
    { 
        local _dotfiles_repo="${REPO:-"https://github.com/axonasif/dotfiles.public"}";
        if ! [[ "$_dotfiles_repo" =~ (https?|git):// ]]; then
            { 
                : "$_dotfiles_repo"
            };
        else
            if is::gitpod; then
                { 
                    : "/tmp/.dotfiles_repo.${RANDOM}"
                };
            else
                { 
                    : "$HOME/.dotfiles-sh_${_dotfiles_repo##*/}"
                };
            fi;
        fi;
        local _generated_source_dir="$_";
        local _source_dir="${SOURCE_DIR:-"$_generated_source_dir"}";
        local _installation_target="${1:-"$HOME"}";
        local last_applied_filelist="$_installation_target/.last_applied";
        if test ! -e "$_source_dir"; then
            { 
                git clone --filter=tree:0 "$_dotfiles_repo" "$_source_dir" > /dev/null 2>&1 || :
            };
        fi;
        if test -e "$last_applied_filelist"; then
            { 
                while read -r file; do
                    { 
                        if test ! -e "$file"; then
                            { 
                                log::info "Cleaning up broken dotfiles link: $file";
                                rm -f "$file" || :
                            };
                        fi
                    };
                done < "$last_applied_filelist"
            };
        fi;
        if test -e "$_source_dir"; then
            { 
                local _dotfiles_ignore="$_source_dir/.dotfilesignore";
                local _thing_path;
                local _ignore_list=(-not -path "'*/.git/*'" -not -path "'*/.dotfilesignore'" -not -path "'$_source_dir/src/*'" -not -path "'$_source_dir/target/*'" -not -path "'$_source_dir/Bashbox.meta'" -not -path "'$_source_dir/install.sh'");
                if test -e "$_dotfiles_ignore"; then
                    { 
                        while read -r _ignore_thing; do
                            { 
                                if [[ ! "$_ignore_thing" =~ ^\# ]]; then
                                    { 
                                        _ignore_thing="$_source_dir/${_ignore_thing}";
                                        _ignore_thing="${_ignore_thing//\/\//\/}";
                                        _ignore_list+=(-not -path "$_ignore_thing")
                                    };
                                fi;
                                unset _ignore_thing
                            };
                        done < "$_dotfiles_ignore"
                    };
                fi;
                printf '' > "$last_applied_filelist";
                local _target_file _target_dir;
                while read -r _file; do
                    { 
                        _target_file="$_installation_target/${_file#${_source_dir}/}";
                        _target_dir="${_target_file%/*}";
                        if test ! -d "$_target_dir"; then
                            { 
                                mkdir -p "$_target_dir"
                            };
                        fi;
                        ln -sf "$_file" "$_target_file";
                        printf '%s\n' "$_target_file" >> "$last_applied_filelist";
                        unset _target_file _target_dir
                    };
                done < <(printf '%s\n' "${_ignore_list[@]}" | xargs find "$_source_dir" -type f)
            };
        fi
    };
    function await::until_true () 
    { 
        local time="${TIME:-0.5}";
        local input=("$@");
        until sleep "$time" && "${input[@]}"; do
            { 
                continue
            };
        done
    };
    function await::for_file_existence () 
    { 
        local file="$1";
        await::until_true test -e "$file"
    };
    function await::for_vscode_ide_start () 
    { 
        if grep -q 'supervisor' /proc/1/cmdline; then
            { 
                gp ports await 23000 > /dev/null
            };
        fi
    };
    function await::signal () 
    { 
        local kind="$1";
        local target="$2";
        local status_file="/tmp/.asignal_${target}";
        case "$kind" in 
            "get")
                until test -s "$status_file"; do
                    { 
                        sleep 0.2
                    };
                done
            ;;
            send)
                printf 'done\n' >> "$status_file"
            ;;
        esac
    };
    function await::create_shim () 
    { 
        function try_sudo () 
        { 
            { 
                "$@" || sudo "$@"
            } 2> /dev/null
        };
        local target shim_source;
        local internal_var_name="DOTFILES_INTERNAL_SHIM_CALL";
        for target in "$@";
        do
            { 
                shim_dir="${target%/*}/.shim";
                shim_source="${shim_dir}/${target##*/}";
                try_sudo mkdir -p "$shim_dir";
                if test -v CLOSE; then
                    { 
                        unset "$internal_var_name";
                        if test -e "$shim_source"; then
                            { 
                                try_sudo mv "$shim_source" "$target";
                                rmdir --ignore-fail-on-non-empty "$shim_dir" 2> /dev/null || :
                            };
                        fi;
                        return
                    };
                fi;
                if test -e "$target"; then
                    { 
                        log::warn "${FUNCNAME[0]}: $target already exists";
                        try_sudo mv "$target" "$shim_source"
                    };
                fi;
                if ! touch "$target" 2> /dev/null; then
                    { 
                        local USER && USER="$(id -u -n)";
                        sudo bash -c "touch \"$target\" && chown -h $USER:$USER \"$target\""
                    };
                fi;
                cat > "$target" <<'SCRIPT'
#!/usr/bin/env bash
set -eu;
self="$(<"$0")"
function main() {
	if test -v "$internal_var_name" && test -e "$shim_source"; then {
		exec "$shim_source" "$@";
	} fi

	diff_target="/tmp/.diff_${RANDOM}.${RANDOM}";
	if test ! -e "$diff_target"; then {
		cp "$target" "$diff_target";
	} fi

	if test -v PRINT_INDICATOR; then {
		printf 'info[shim]: Loading %s\n' "$target";
	} fi

	function await() {
		while cmp --silent -- "$target" "$diff_target"; do {
			sleep 0.2;
		} done

		while lsof -F 'f' -- "$target" 2>/dev/null | grep -q '^f.*w$'; do {
			sleep 0.2;
		} done
	}

	await;
SCRIPT

                if test -v KEEP; then
                    { 
                        eval "export $internal_var_name=ture";
                        cat >> "$target" <<'SCRIPT'
	# For internal calls
	if test -v $internal_var_name; then {
		if test ! -e "$shim_source"; then {
			sudo mv "$target" "$shim_source";
			sudo env self="$self" target="$target" bash -c 'printf "%s\n" "$self" > "$target" && chmod +x $target';
		} fi
		exec "$shim_source" "$@";
	} fi

	# For external calls
	while test -e "$shim_source"; do {
		sleep 0.2;
	} done
SCRIPT

                    };
                fi
                { 
                    printf '\texec %s "$@"\n\n}\n\n' "$target";
                    printf '%s="%s"\n' target "$target" shim_source "$shim_source" internal_var_name "$internal_var_name";
                    printf '%s\n' "$(declare -f sleep)";
                    printf 'main "$@"\n'
                } >> "$target";
                chmod +x "$target"
            };
        done
    };
    levelone_syspkgs=(tmux fish jq lsof);
    function install::system_packages () 
    { 
        log::info "Installing system packages";
        { 
            sudo apt-get update;
            sudo debconf-set-selections <<< 'debconf debconf/frontend select Noninteractive';
            sudo apt-get install -yq --no-install-recommends "${levelone_syspkgs[@]}";
            sudo apt-get install -yq --no-install-recommends "${leveltwo_syspkgs[@]}";
            sudo debconf-set-selections <<< 'debconf debconf/frontend select Readline'
        } > /dev/null 2>&1
    };
    function install::userland_tools () 
    { 
        log::info "Installing userland tools";
        curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall > /dev/null 2>&1 & disown;
        USER="$(id -u -n)" && export USER;
        if test ! -e /nix; then
            { 
                log::info "Installing nix";
                curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon > /dev/null 2>&1
            };
        fi;
        source "$HOME/.nix-profile/etc/profile.d/nix.sh" || source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh;
        local pkgs=(nixpkgs.hollywood nixpkgs.shellcheck nixpkgs.tree nixpkgs.file nixpkgs.fzf nixpkgs.bat nixpkgs.bottom nixpkgs.exa nixpkgs.fzf nixpkgs.neofetch nixpkgs.ripgrep nixpkgs.shellcheck nixpkgs.tree nixpkgs.zoxide);
        nix-env -iA "${pkgs[@]}" > /dev/null 2>&1
    };
    function install::ranger () 
    { 
        if ! command -v pip3 > /dev/null; then
            { 
                log::error "Python not installed" 1 || exit
            };
        fi;
        bash -lic 'pip3 install --no-input ranger-fm' > /dev/null;
        local target=$HOME/.config/ranger/rc.conf;
        local target_dir="${target%/*}";
        local devicons_activation_string="default_linemode devicons";
        if ! grep -q "$devicons_activation_string" "$target" 2> /dev/null; then
            { 
                mkdir -p "$target_dir";
                printf '%s\n' "$devicons_activation_string" >> "$target"
            };
        fi;
        local devicons_plugin_dir="$target_dir/plugins/ranger_devicons";
        if test ! -e "$devicons_plugin_dir"; then
            { 
                git clone --filter=tree:0 https://github.com/alexanderjeurissen/ranger_devicons "$devicons_plugin_dir" > /dev/null 2>&1
            };
        fi
    };
    function install::gh () 
    { 
        local tarball_url gp_credentials;
        if ! command -v gh > /dev/null; then
            { 
                log::info "Installing gh CLI and logging in";
                tarball_url="$(curl -Ls "https://api.github.com/repos/cli/cli/releases/latest" 			| grep -o 'https://github.com/.*/releases/download/.*/gh_.*linux_amd64.tar.gz')";
                curl -Ls "$tarball_url" | sudo tar -C /usr --strip-components=1 -xpzf -
            };
        fi;
        if is::gitpod; then
            { 
                await::for_vscode_ide_start;
                if token="$(printf '%s\n' host=github.com | gp credential-helper get | awk -F'password=' 'BEGIN{RS=""} {print $2}')"; then
                    { 
                        tries=1;
                        until printf '%s\n' "${token}" | gh auth login --with-token &> /dev/null; do
                            { 
                                if test $tries -gt 20; then
                                    { 
                                        log::error "Failed to authenticate to 'gh' CLI with 'gp' credentials" 1 || exit;
                                        break
                                    };
                                fi;
                                ((tries++));
                                sleep 1;
                                continue
                            };
                        done
                    };
                else
                    { 
                        log::error "Failed to get auth token for gh" || exit 1
                    };
                fi
            };
        fi
    };
    function install::dotfiles () 
    { 
        log::info "Installing public dotfiles";
        REPO="${DOTFILES_PRIMARY_REPO:-}" dotfiles::initialize;
        await::signal send install_dotfiles
    };
    function install::neovim () 
    { 
        log::info "Installing and setting up Neovim";
        curl -Ls "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz" | sudo tar -C /usr --strip-components=1 -xpzf -;
        curl -sL "https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh" | bash -s -- --no-install-dependencies -y > /dev/null 2>&1;
        await::signal get config_tmux;
        tmux send-keys -t "${tmux_first_session_name}:${tmux_first_window_num}" "nvim --version" Enter
    };
    function config::docker_auth () 
    { 
        local var_name=DOCKER_AUTH_TOKEN;
        local target="$HOME/.docker/config.json";
        if test -v $var_name; then
            { 
                log::info "Setting up docker login credentials";
                mkdir -p "${target%/*}";
                printf '{"auths":{"https://index.docker.io/v1/":{"auth":"%s"}}}\n' "${!var_name}" > "$target"
            };
        else
            { 
                log::warn "$var_name is not set"
            };
        fi
    };
    readonly RC='\033[0m' RED='\033[0;31m' BRED='\033[1;31m' GRAY='\033[1;30m';
    readonly BLUE='\033[0;34m' BBLUE='\033[1;34m' CYAN='\033[0;34m' BCYAN='\033[1;34m';
    readonly WHITE='\033[1;37m' GREEN='\033[0;32m' BGREEN='\033[1;32m' YELLOW='\033[1;33m';
    readonly PURPLE='\033[0;35m' BPURPLE='\033[1;35m' ORANGE='\033[0;33m';
    function tmux::create_session () 
    { 
        tmux new-session -n home -ds "${tmux_first_session_name}"\; send-keys -t :${tmux_first_window_num} "cat $HOME/.dotfiles.log" Enter 2> /dev/null || :;
        tmux_default_shell="$(tmux display -p '#{default-shell}')"
    };
    function tmux::create_window () 
    { 
        tmux new-window -n "${WINDOW_NAME:-vs:${PWD##*/}}" -t "$tmux_first_session_name" "$@"
    };
    function tmux::start_vimpod () 
    { 
        local lockfile=/tmp/.vimpod;
        if test -e "$lockfile"; then
            return 0;
        fi;
        touch "$lockfile";
        "$___self_DIR/src/utils/vimpod.py" & disown;
        ( { 
            gp ports await 23000 && gp ports await 22000
        } > /dev/null && gp preview "$(gp url 22000)" --external && { 
            if test "${DOTFILES_NO_VSCODE:-false}" == "true"; then
                { 
                    printf '%s\n' '#!/usr/bin/env sh' 'while sleep $(( 60 * 60 )); do continue; done' > /ide/bin/gitpod-code;
                    pkill -9 -f 'sh /ide/bin/gitpod-code'
                };
            fi
        } ) & disown
    };
    function inject_tmux_old_complicated () 
    { 
        if test -v TMUX; then
            { 
                return
            };
        fi;
        local tmux tmux_default_shell;
        function create_session () 
        { 
            tmux new-session -n home -ds "${tmux_first_session_name}"\; send-keys -t :${tmux_first_window_num} "cat $HOME/.dotfiles.log" Enter 2> /dev/null;
            tmux_default_shell="$(tmux display -p '#{default-shell}')"
        };
        function new_window () 
        { 
            exec tmux new-window -n "${WINDOW_NAME:-vs:${PWD##*/}}" -t main "$@"
        };
        function create_window () 
        { 
            if test ! -e "$tmux_init_lock" && test -z "$(tmux list-clients -t "$tmux_first_session_name")"; then
                { 
                    touch "$tmux_init_lock";
                    new_window "$@" \; attach
                };
            else
                { 
                    new_window "$@"
                };
            fi
        };
        function get_task_term_name () 
        { 
            local file_loc="/tmp/.gp_tasks_names";
            if test ! -e "$file_loc"; then
                { 
                    local term_id term_name task_state symbol ref;
                    while IFS='|' read -r _ term_id term_name task_state _; do
                        { 
                            if [[ "$term_id" =~ [0-9]+ ]]; then
                                { 
                                    for symbol in term_id term_name task_state;
                                    do
                                        { 
                                            declare -n ref="$symbol";
                                            ref="${ref% }" && ref="${ref# }"
                                        };
                                    done;
                                    if test "$task_state" == "running"; then
                                        { 
                                            printf '%s\n' "$term_name" >> "$file_loc"
                                        };
                                    fi;
                                    unset symbol ref
                                };
                            fi
                        };
                    done < <(gp tasks list --no-color)
                };
            fi;
            if test -e "$file_loc"; then
                { 
                    awk '{$1=$1;print;exit}' "$file_loc";
                    sed -i '1d' "$file_loc"
                };
            fi
        };
        if test ! -e "$tmux_init_lock"; then
            { 
                "$___self_DIR/src/utils/vimpod.py" & disown;
                ( { 
                    gp ports await 23000 && gp ports await 22000
                } > /dev/null && gp preview "$(gp url 22000)" --external && { 
                    if test "${DOTFILES_NO_VSCODE:-false}" == "true"; then
                        { 
                            printf '%s\n' '#!/usr/bin/env sh' 'while sleep $(( 60 * 60 )); do continue; done' > /ide/bin/gitpod-code;
                            pkill -9 -f 'sh /ide/bin/gitpod-code'
                        };
                    fi
                } ) &
            };
        fi;
        touch "$tmux_init_lock";
        if [ "$BASH" == /bin/bash ] || [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ]; then
            { 
                if test -v SSH_CONNECTION; then
                    { 
                        if test "${DOTFILES_NO_VSCODE:-false}" == "true"; then
                            { 
                                pkill -9 vimpod || :
                            };
                        fi;
                        create_session;
                        exec tmux set-window-option -g -t "${tmux_first_session_name}" window-size largest\; attach -t :${tmux_first_window_num}
                    };
                fi;
                create_session;
                termout=/tmp/.termout.$$;
                if test ! -v bash_ran_once; then
                    { 
                        exec > >(tee -a "$termout") 2>&1
                    };
                fi;
                local stdin;
                IFS= read -t0.01 -u0 -r -d '' stdin;
                if test -n "$stdin"; then
                    { 
                        if test "${DEBUG_DOTFILES:-false}" == true; then
                            { 
                                declare -p stdin;
                                read -rp running;
                                set -x
                            };
                        fi;
                        stdin=$(printf '%q' "$stdin");
                        WINDOW_NAME="$(get_task_term_name)" create_window bash -c "trap 'exec $tmux_default_shell -l' EXIT; less -FXR $termout | cat; printf '%s\n' $stdin; eval $stdin;"
                    };
                else
                    { 
                        if test "${DEBUG_DOTFILES:-false}" == true; then
                            { 
                                read -rp exiting
                            };
                        fi;
                        exit
                    };
                fi;
                bash_ran_once=true
            };
        else
            { 
                unset ${FUNCNAME[0]} && PROMPT_COMMAND="${PROMPT_COMMAND/${FUNCNAME[0]};/}"
            };
        fi
    };
    function inject_tmux () 
    { 
        if [ "$BASH" == /bin/bash ] || [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ]; then
            { 
                if test -v TMUX; then
                    { 
                        return
                    };
                fi;
                if test -v SSH_CONNECTION; then
                    { 
                        if test "${DOTFILES_NO_VSCODE:-false}" == "true"; then
                            { 
                                pkill -9 vimpod || :
                            };
                        fi;
                        tmux::create_session;
                        exec tmux set-window-option -g -t "${tmux_first_session_name}" window-size largest\; attach \; attach -t :${tmux_first_window_num}
                    };
                else
                    { 
                        exit 0
                    };
                fi
            };
        fi
    };
    function config::tmux::hijack_gitpod_task_terminals () 
    { 
        if ! grep -q 'PROMPT_COMMAND=".*inject_tmux.*"' "$HOME/.bashrc" 2> /dev/null; then
            { 
                log::info "Setting tmux as the interactive shell for Gitpod task terminals";
                printf '%s\n' "tmux_first_session_name=$tmux_first_session_name" "tmux_first_window_num=$tmux_first_window_num" "tmux_init_lock=$tmux_init_lock" "$(declare -f tmux::start_vimpod tmux::create_session inject_tmux)" 'PROMPT_COMMAND="inject_tmux;$PROMPT_COMMAND"' >> "$HOME/.bashrc"
            };
        fi
    };
    function config::tmux::set_tmux_as_default_vscode_shell () 
    { 
        log::info "Setting the integrated tmux shell for VScode as default";
        local json_data;
        json_data="$(cat <<-'JSON' | sed "s|main|${tmux_first_session_name}|g"
		{
			"terminal.integrated.profiles.linux": {
				"tmuxshell": {
					"path": "bash",
					"args": [
						"-c",
						"until command -v tmux 1>/dev/null; do sleep 1; done; tmux new-session -ds main 2>/dev/null || :; if cpids=$(tmux list-clients -t main -F '#{client_pid}'); then for cpid in $cpids; do [ $(ps -o ppid= -p $cpid)x == ${PPID}x ] && exec tmux new-window -n \"vs:${PWD##*/}\" -t main; done; fi; exec tmux attach -t main; "
					]
				}
			},
			"terminal.integrated.defaultProfile.linux": "tmuxshell"
		}
	JSON
	)";
        printf '%s\n' "$json_data" | vscode::add_settings;
        local dir;
        for dir in '.vscode-server' '.vscode-remote';
        do
            { 
                printf '%s\n' "$json_data" | SETTINGS_TARGET="$HOME/$dir/data/Machine/settings.json" vscode::add_settings
            };
        done
    };
    function config::tmux () 
    { 
        config::tmux::set_tmux_as_default_vscode_shell & disown;
        config::tmux::hijack_gitpod_task_terminals & if is::gitpod && test "${DOTFILES_SPAWN_SSH_PROTO:-true}" == true; then
            { 
                tmux::start_vimpod & disown
            };
        fi;
        local tmux_exec_path="/usr/bin/tmux";
        KEEP="true" await::create_shim "$tmux_exec_path";
        log::info "Setting up tmux";
        local target="$HOME/.tmux/plugins/tpm";
        if test ! -e "$target"; then
            { 
                git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target" > /dev/null 2>&1;
                await::signal get install_dotfiles;
                bash -lic "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" > /dev/null 2>&1;
                CLOSE=true await::create_shim "$tmux_exec_path"
            };
        fi;
        local tmux_default_shell;
        tmux::create_session;
        await::signal send config_tmux;
        if is::gitpod; then
            { 
                if test ! -v GITPOD_TASKS; then
                    { 
                        return
                    };
                else
                    { 
                        log::info "Spawning Gitpod tasks in tmux"
                    };
                fi;
                await::for_file_existence "$workspace_dir/.gitpod/ready";
                cd "$GITPOD_REPO_ROOT";
                function jqw () 
                { 
                    local cmd;
                    if cmd=$(jq -er "$@" <<<"$GITPOD_TASKS") 2> /dev/null; then
                        { 
                            printf '%s\n' "$cmd"
                        };
                    else
                        { 
                            return 1
                        };
                    fi
                };
                local name cmd arr_elem=0 cmdfile;
                while cmd="$(jqw ".[${arr_elem}] | [.init, .before, .command] | map(select(. != null)) | .[]")"; do
                    { 
                        if ! name="$(jqw ".[${arr_elem}].name")"; then
                            { 
                                name="AnonTask-${arr_elem}"
                            };
                        fi;
                        cmdfile="/tmp/.cmd-${arr_elem}";
                        printf '%s\n' "$cmd" > "$cmdfile";
                        WINDOW_NAME="$name" tmux::create_window bash -lc "trap 'exec $tmux_default_shell -l' EXIT; cat $workspace_dir/.gitpod/prebuild-log-${arr_elem} 2>/dev/null && exit; printf \"$BGREEN>> Executing task:$RC\n\"; printf \"${YELLOW}%s${RC}\n\" \"$(< $cmdfile)\" | awk '{print \"  \" \$0}'; printf '\n\n'; source $cmdfile; exit";
                        ((arr_elem=arr_elem+1))
                    };
                done
            };
        else
            if is::codespaces; then
                { 
                    cd "$CODESPACE_VSCODE_FOLDER"
                };
            fi;
        fi
    };
    local -r _shell_hist_files=("${HISTFILE:-"$HOME/.bash_history"}" "${HISTFILE:-"$HOME/.zsh_history"}" "$HOME/.local/share/fish/fish_history");
    function config::shell::persist_history () 
    { 
        log::info "Persiting Gitpod shell histories to $workspace_dir";
        local _workspace_persist_dir="$workspace_dir/.persist";
        mkdir -p "$_workspace_persist_dir";
        local _hist;
        for _hist in "${_shell_hist_files[@]}";
        do
            { 
                mkdir -p "${_hist%/*}";
                _hist_name="${_hist##*/}";
                if test -e "$_workspace_persist_dir/$_hist_name"; then
                    { 
                        log::info "Overwriting $_hist with workspace persisted history file";
                        ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist"
                    };
                else
                    { 
                        touch "$_hist";
                        cp "$_hist" "$_workspace_persist_dir/";
                        ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist"
                    };
                fi;
                unset _hist_name
            };
        done
    };
    function config::shell::fish::append_hist_from_gitpod_tasks () 
    { 
        if ! is::gitpod; then
            { 
                return
            };
        fi;
        log::info "Appending .gitpod.yml:tasks shell histories to fish_history";
        while read -r _command; do
            { 
                if test -n "$_command"; then
                    { 
                        printf '\055 cmd: %s\n  when: %s\n' "$_command" "$(date +%s)" >> "${_shell_hist_files[2]}"
                    };
                fi
            };
        done < <(sed "s/\r//g" /workspace/.gitpod/cmd-* 2>/dev/null || :)
    };
    function config::fish () 
    { 
        log::info "Installing fisher and some plugins for fish-shell";
        await::until_true command -v fish > /dev/null;
        { 
            fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
        } > /dev/null 2>&1
    };
    declare -r workspace_dir="$(
	if is::gitpod; then {
		printf '%s\n' "/workspace";
	} elif is::codespaces; then {
		printf '%s\n' "/workspaces";
	} fi
)";
    declare -r vscode_machine_settings_file="$(
	if is::gitpod; then {
		: "$workspace_dir";
	} else {
		: "$HOME";
	} fi
	printf '%s\n' "$_/.vscode-remote/data/Machine/settings.json";
)";
    declare -r tmux_first_session_name="main";
    declare -r tmux_first_window_num="1";
    declare -r tmux_init_lock="/tmp/.tmux.init";
    declare -r fish_confd_dir="$HOME/.config/fish/conf.d" && mkdir -p "$fish_confd_dir";
    function main () 
    { 
        if is::codespaces; then
            { 
                local log_file="$HOME/.dotfiles.log";
                exec >> "$log_file";
                exec 2>&1
            };
        fi;
        install::dotfiles & disown;
        if is::gitpod || is::codespaces; then
            { 
                config::tmux & disown;
                config::shell::persist_history;
                config::shell::fish::append_hist_from_gitpod_tasks & disown;
                config::fish & disown;
                install::system_packages & disown;
                install::userland_tools & disown;
                config::docker_auth & disown;
                install::neovim & disown;
                install::gh & disown;
                install::ranger & disown
            };
        fi;
        log::info "Waiting for background jobs to complete" && jobs -l;
        while test -n "$(jobs -p)" && sleep 0.2; do
            { 
                printf '.';
                continue
            };
        done;
        log::info "Dotfiles script exited in ${SECONDS} seconds"
    };
    main "$@";
    wait;
    exit
}
main@bashbox%763 "$@";
