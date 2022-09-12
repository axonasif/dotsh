#!/usr/bin/env bash
main@bashbox%28203 () 
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
    ___MAIN_FUNCNAME='main@bashbox%28203';
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
        chmod 0755 "$root_script"
    };
    function bashbox::build::before () 
    { 
        rm -rf "$_arg_path/.private"
    };
    function live () 
    { 
        ( cmd="bashbox build --release";
        log::info "Running '$cmd";
        $cmd;
        local duplicate_repo_root="/tmp/.mrroot";
        log::info "Creating a clone of $GITPOD_REPO_ROOT at $duplicate_repo_root" && { 
            rm -rf "$duplicate_repo_root";
            cp -ra "$GITPOD_REPO_ROOT" "$duplicate_repo_root"
        };
        local ide_mirror="/tmp/.idem";
        if test ! -e "$ide_mirror"; then
            { 
                log::info "Creating /ide mirror";
                cp -ra /ide "$ide_mirror"
            };
        fi;
        log::info "Starting a fake Gitpod workspace with headless IDE" && { 
            local ide_cmd ide_port;
            ide_cmd="$(ps -p $(pgrep -f 'sh /ide/bin/gitpod-code --install-builtin-extension') -o args --no-headers)";
            ide_port="33000";
            ide_cmd="${ide_cmd//23000/${ide_port}} >/ide/server_log 2>&1";
            local docker_args=(run --net=host -v "$duplicate_repo_root:/$GITPOD_REPO_ROOT" -v "$duplicate_repo_root:$HOME/.dotfiles" -v "$ide_mirror:/ide" -v /usr/bin/gp:/usr/bin/gp:ro -e GP_EXTERNAL_BROWSER -e GP_OPEN_EDITOR -e GP_PREVIEW_BROWSER -e GITPOD_ANALYTICS_SEGMENT_KEY -e GITPOD_ANALYTICS_WRITER -e GITPOD_CLI_APITOKEN -e GITPOD_GIT_USER_EMAIL -e GITPOD_GIT_USER_NAME -e GITPOD_HOST -e GITPOD_IDE_ALIAS -e GITPOD_INSTANCE_ID -e GITPOD_INTERVAL -e GITPOD_MEMORY -e GITPOD_OWNER_ID -e GITPOD_PREVENT_METADATA_ACCESS -e GITPOD_REPO_ROOT -e GITPOD_REPO_ROOTS -e GITPOD_TASKS -e GITPOD_THEIA_PORT -e GITPOD_WORKSPACE_CLASS -e GITPOD_WORKSPACE_CLUSTER_HOST -e GITPOD_WORKSPACE_CONTEXT -e GITPOD_WORKSPACE_CONTEXT_URL -e GITPOD_WORKSPACE_ID -e GITPOD_WORKSPACE_URL -it gitpod/workspace-base:latest /bin/sh -lic "eval \$(gp env -e); $ide_cmd & \$HOME/.dotfiles/install.sh; exec bash -l");
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
    declare -r workspace_dir="/workspace";
    declare -r vscode_machine_settings_file="/workspace/.vscode-remote/data/Machine/settings.json";
    declare -r tmux_first_session_name="main";
    declare -r tmux_first_window_num="1";
    declare -r tmux_init_lock="/tmp/.tmux.init";
    function is::gitpod () 
    { 
        test -e /ide/bin/gitpod-code && test -v GITPOD_REPO_ROOT
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
                        mkdir -p "${vscode_machine_settings_file%/*}"
                    };
                fi;
                wait::for_file_existence "/usr/bin/jq";
                if test ! -s "$vscode_machine_settings_file" || ! jq -reM '""' "$vscode_machine_settings_file" > /dev/null; then
                    { 
                        printf '{}\n' > "$vscode_machine_settings_file"
                    };
                fi;
                sed -i -e 's|,}|\n}|g' -e 's|, }|\n}|g' -e ':begin;$!N;s/,\n}/\n}/g;tbegin;P;D' "$vscode_machine_settings_file";
                local tmp_file="${vscode_machine_settings_file%/*}/.tmp";
                cp -a "$vscode_machine_settings_file" "$tmp_file";
                jq -s '.[0] * .[1]' - "$tmp_file" <<< "$input" > "$vscode_machine_settings_file";
                rm "$tmp_file"
            };
        fi
    };
    function dotfiles::initialize () 
    { 
        local _dotfiles_repo="${REPO:-"$___self_REPOSITORY"}";
        if is::gitpod; then
            { 
                : "/tmp/.dotfiles_repo.${RANDOM}"
            };
        else
            { 
                : "$HOME/.dotfiles-sh_${_dotfiles_repo##*/}"
            };
        fi;
        local _generated_source_dir="";
        local _source_dir="${1:-"$_generated_source_dir"}";
        local _installation_target="${2:-"$HOME"}";
        local last_applied_filelist="$___self_DIR/.git/.last_applied";
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
    function wait::until_true () 
    { 
        local time="${TIME:-0.5}";
        local input=("$@");
        until sleep "$time" && "${input[@]}"; do
            { 
                continue
            };
        done
    };
    function wait::for_file_existence () 
    { 
        local file="$1";
        wait::until_true test -e "$file"
    };
    function wait::for_vscode_ide_start () 
    { 
        if grep -q 'supervisor' /proc/1/cmdline; then
            { 
                gp ports await 23000 > /dev/null
            };
        fi
    };
    levelone_syspkgs=(tmux fish jq);
    leveltwo_syspkgs=(hollywood shellcheck rsync tree file mosh fzf);
    function install::system_packages () 
    { 
        log::info "Installing system packages";
        { 
            sudo apt-get update;
            sudo debconf-set-selections <<< 'debconf debconf/frontend select Noninteractive';
            sudo apt-get install -yq --no-install-recommends "${levelone_syspkgs[@]}";
            sudo apt-get install -yq --no-install-recommends "${leveltwo_syspkgs[@]}";
            sudo debconf-set-selections <<< 'debconf debconf/frontend select Readline'
        } > /dev/null
    };
    function install::userland_tools () 
    { 
        log::info "Installing userland tools";
        curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall & disown
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
        log::info "Installing gh CLI and logging in";
        tarball_url="$(curl -Ls "https://api.github.com/repos/cli/cli/releases/latest" 		| grep -o 'https://github.com/.*/releases/download/.*/gh_.*linux_amd64.tar.gz')";
        curl -Ls "$tarball_url" | sudo tar -C /usr --strip-components=1 -xpzf -;
        wait::for_vscode_ide_start;
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
    function install::dotfiles () 
    { 
        log::info "Installing public dotfiles";
        REPO="${DOTFILES_PRIMARY_REPO:-https://github.com/axonasif/dotfiles.public}" dotfiles::initialize
    };
    function install::neovim () 
    { 
        log::info "Installing and setting up Neovim";
        local nvim_conf_dir="$HOME/.config/nvim";
        if test -e "$nvim_conf_dir" && nvim_conf_bak="${nvim_conf_dir}.bak"; then
            { 
                mv "$nvim_conf_dir" "$nvim_conf_bak"
            };
        fi;
        curl -Ls "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz" | sudo tar -C /usr --strip-components=1 -xpzf -;
        git clone --filter=tree:0 https://github.com/axonasif/NvChad "$nvim_conf_dir" > /dev/null 2>&1;
        wait::for_file_existence "$tmux_init_lock" && wait::until_true tmux list-session > /dev/null 2>&1;
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
        local file json_data;
        local ms_vscode_server_dir="$HOME/.vscode-server";
        local ms_vscode_server_settings="$ms_vscode_server_dir/data/Machine/settings.json";
        json_data="$(cat <<-'JSON' | sed "s|main|${tmux_first_session_name}|g"
		{
			"terminal.integrated.profiles.linux": {
				"tmuxshell": {
					"path": "bash",
					"args": [
						"-c",
						"tmux new-session -ds main 2>/dev/null || :; if cpids=$(tmux list-clients -t main -F '#{client_pid}'); then for cpid in $cpids; do [ $(ps -o ppid= -p $cpid)x == ${PPID}x ] && exec tmux new-window -n \"vs:${PWD##*/}\" -t main; done; fi; exec tmux attach -t main; "
					]
				}
			},
			"terminal.integrated.defaultProfile.linux": "tmuxshell"
		}
	JSON
	)";
        printf '%s\n' "$json_data" | vscode::add_settings;
        printf '%s\n' "$json_data" | SETTINGS_TARGET="$ms_vscode_server_settings" vscode::add_settings
    };
    function tmux::create_awaiter () 
    { 
        ( tmux_exec_path="$1";
        : "${USER:="$(id -un)"}";
        sudo bash -c "touch $tmux_exec_path && chown $USER:$USER $tmux_exec_path && chmod +x $tmux_exec_path";
        cat <<-SHELL > "$tmux_exec_path"
#!/usr/bin/env bash
{
printf 'info: %s\n' "Tmux is being loaded... any moment now!";

until test -e "$tmux_init_lock"; do {
sleep 1;
} done

if test -z "${@}"; then {
exec "$tmux_exec_path" new-session -As "$tmux_first_session_name";
} else {
exec "$tmux_exec_path" "$@";
} fi
}
SHELL
 )
    }
    function config::tmux () 
    { 
        config::tmux::set_tmux_as_default_vscode_shell & disown;
        config::tmux::hijack_gitpod_task_terminals & local tmux_exec_path="/usr/bin/tmux";
        tmux::create_awaiter "$tmux_exec_path" & disown;
        if test "${DOTFILES_SPAWN_SSH_PROTO:-true}" == true; then
            { 
                tmux::start_vimpod & disown
            };
        fi;
        log::info "Setting up tmux";
        local target="$HOME/.tmux/plugins/tpm";
        if test ! -e "$target"; then
            { 
                { 
                    git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target" > /dev/null 2>&1;
                    local main_tmux_conf="$HOME/.tmux.conf";
                    local tmp_tmux_conf="$HOME/.tmux.tmp.conf";
                    if test -e "$main_tmux_conf" && test ! -e "$tmp_tmux_conf"; then
                        { 
                            mv "$main_tmux_conf" "$tmp_tmux_conf"
                        };
                    fi;
                    cat <<-CONF > "$main_tmux_conf"
set -g base-index 1
setw -g pane-base-index 1
source-file ~/.tmux_plugins.conf
set -g default-command "tmux rename-session $tmux_first_session_name; tmux rename-window home; printf '%s\n' 'Loading tmux ...'; until test -e $tmux_init_lock; do sleep 0.5; done; tmux source-file ~/.tmux.conf; exec bash -l"
CONF

                    wait::until_true test ! -O "$tmux_exec_path";
                    bash "$HOME/.tmux/plugins/tpm/bin/install_plugins";
                    if test -e "$tmp_tmux_conf"; then
                        { 
                            mv "$tmp_tmux_conf" "$main_tmux_conf"
                        };
                    fi;
                    touch "$tmux_init_lock"
                } > /dev/null
            };
        fi;
        if test ! -v GITPOD_TASKS; then
            { 
                return
            };
        fi;
        log::info "Spawning Gitpod tasks in tmux";
        local tmux_default_shell;
        tmux::create_session;
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
        wait::for_file_existence "/workspace/.gitpod/ready";
        cd "$GITPOD_REPO_ROOT";
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
                WINDOW_NAME="$name" tmux::create_window bash -lc "trap 'exec $tmux_default_shell -l' EXIT; cat /workspace/.gitpod/prebuild-log-${arr_elem} 2>/dev/null && exit; printf \"$BGREEN>> Executing task:$RC\n\"; printf \"${YELLOW}%s${RC}\n\" \"$(< $cmdfile)\" | awk '{print \"\\t\" \$0}'; source $cmdfile; exit";
                ((arr_elem=arr_elem+1))
            };
        done
    };
    local -r _shell_hist_files=("${HISTFILE:-"$HOME/.bash_history"}" "${HISTFILE:-"$HOME/.zsh_history"}" "$HOME/.local/share/fish/fish_history");
    function config::shell::persist_history () 
    { 
        log::info "Persiting Gitpod shell histories to /workspace";
        local _workspace_persist_dir="/workspace/.persist";
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
    function main () 
    { 
        install::dotfiles & if is::gitpod; then
            { 
                log::info "Gitpod environment detected!";
                install::system_packages & disown;
                install::userland_tools & disown;
                config::docker_auth & disown;
                config::shell::persist_history;
                config::shell::fish::append_hist_from_gitpod_tasks & disown;
                config::tmux & disown;
                install::neovim & disown;
                install::gh & disown
            };
        fi;
        install::ranger & disown;
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
main@bashbox%28203 "$@";
