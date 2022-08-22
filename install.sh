#!/usr/bin/env bash
main@bashbox%27132 () 
{ 
    function process::self::exit () 
    { 
        local _r=$?;
        kill -USR1 "$___self_PID";
        exit $_r
    };
    function process::self::forcekill () 
    { 
        exec 2> /dev/null;
        kill -9 "$___self_PID"
    };
    function log::error () 
    { 
        local _retcode="${2:-$?}";
        local _exception_line="$1";
        local _source="${BB_ERR_SOURCE:-"${BASH_SOURCE[-1]}"}";
        if [[ ! "$_exception_line" == "("*")" ]]; then
            { 
                echo -e "[!!!] \033[1;31merror\033[0m[$_retcode]: ${_source##*/}[$BASH_LINENO]: ${BB_ERR_MSG:-"$_exception_line"}" 1>&2;
                if test -v BB_ERR_MSG; then
                    { 
                        echo -e "STACK TRACE: (TOKEN: $_exception_line)" 1>&2;
                        local -i _frame=0;
                        local _treestack='|--';
                        local _line _caller _source;
                        while read -r _line _caller _source < <(caller "$_frame"); do
                            { 
                                echo "$_treestack ${_caller} >> ${_source##*/}::${_line}" 1>&2;
                                _frame+=1;
                                _treestack+='--'
                            };
                        done
                    };
                fi
            };
        else
            { 
                echo -e "[!!!] \033[1;31merror\033[0m[$_retcode]: ${_source##*/}[$BASH_LINENO]: SUBSHELL EXITED WITH NON-ZERO STATUS" 1>&2
            };
        fi;
        return "$_retcode"
    };
    \command \unalias -a || exit;
    set -eEuT -o pipefail;
    shopt -s inherit_errexit expand_aliases;
    trap 'exit' USR1;
    trap 'BB_ERR_MSG="UNCAUGHT EXCEPTION" log::error "$BASH_COMMAND" || process::self::exit' ERR;
    ___self="$0";
    ___self_PID="$$";
    ___MAIN_FUNCNAME="main@bashbox%27132";
    ___self_NAME="dotfiles";
    ___self_CODENAME="dotfiles";
    ___self_AUTHORS=("AXON <axonasif@gmail.com>");
    ___self_VERSION="1.0";
    ___self_DEPENDENCIES=(std::0.2.0);
    ___self_REPOSITORY="https://github.com/axonasif/dotfiles.git";
    ___self_BASHBOX_COMPAT="0.3.9~";
    function bashbox::build::after () 
    { 
        local _script_name='install.sh';
        local root_script="$_arg_path/$_script_name";
        cp "$_target_workfile" "$root_script";
        chmod 0755 "$root_script"
    };
    function bashbox::run::before () 
    { 
        rm -rf .private
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
        read -rt "$1" 0<> <(:) || :
    };
    declare -r workspace_dir="/workspace";
    declare -r vscode_machine_settings_file="/workspace/.vscode-remote/data/Machine/settings.json";
    local source_dir="$(readlink -f "$0")" && declare -r source_dir="${source_dir%/*}";
    function is::gitpod () 
    { 
        test -e /ide/bin/gitpod-code && test -v GITPOD_REPO_ROOT
    };
    function vscode::add_settings () 
    { 
        local lockfile="/tmp/.vscs_add.lock";
        trap "rm -f $lockfile" ERR SIGINT;
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
                if ! jq -e . "$vscode_machine_settings_file" > /dev/null 2>&1; then
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
    function wait::for_file_existence () 
    { 
        local file="$1";
        until sleep 0.5 && test -e "$file"; do
            { 
                continue
            };
        done
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
    leveltwo_syspkgs=(shellcheck rsync tree file mosh neovim);
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
        curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall
    };
    function install::tmux () 
    { 
        log::info "Setting up tmux";
        local target="$HOME/.tmux/plugins/tpm";
        if test ! -e "$target"; then
            { 
                { 
                    git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target" > /dev/null 2>&1;
                    wait::for_file_existence "/usr/bin/tmux";
                    bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
                } > /dev/null
            };
        fi
    };
    function install::ranger () 
    { 
        bash -lic 'pip install --no-input ranger-fm' > /dev/null;
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
                printf '%s\n' "${token}" | gh auth login --with-token
            };
        else
            { 
                log::error "Failed to get auth token for gh" || exit 1
            };
        fi
    };
    function install::dotfiles () 
    { 
        local _dotfiles_repo="${1}";
        local _dotfiles_dir="${2}";
        local _target_file _target_dir;
        local _git_output;
        if test ! -e "$_dotfiles_dir"; then
            { 
                git clone --filter=tree:0 "$_dotfiles_repo" "$_dotfiles_dir" > /dev/null 2>&1 || :
            };
        fi;
        if test -e "$_dotfiles_dir"; then
            { 
                local _dotfiles_ignore="$_dotfiles_dir/.dotfilesignore";
                local _thing_path;
                local _ignore_list=(-not -path "'*/.git/*'" -not -path "'*/.dotfilesignore'" -not -path "'$_dotfiles_dir/src/*'" -not -path "'$_dotfiles_dir/target/*'" -not -path "'$_dotfiles_dir/Bashbox.meta'" -not -path "'$_dotfiles_dir/install.sh'");
                if test -e "$_dotfiles_ignore"; then
                    { 
                        while read -r _ignore_thing; do
                            { 
                                if [[ ! "$_ignore_thing" =~ ^\# ]]; then
                                    { 
                                        _ignore_thing="$_dotfiles_dir/${_ignore_thing}";
                                        _ignore_thing="${_ignore_thing//\/\//\/}";
                                        _ignore_list+=(-not -path "$_ignore_thing")
                                    };
                                fi;
                                unset _ignore_thing
                            };
                        done < "$_dotfiles_ignore"
                    };
                fi;
                while read -r _file; do
                    { 
                        _target_file="$HOME/${_file#${_dotfiles_dir}/}";
                        _target_dir="${_target_file%/*}";
                        if test ! -d "$_target_dir"; then
                            { 
                                mkdir -p "$_target_dir"
                            };
                        fi;
                        ln -sf "$_file" "$_target_file";
                        unset _target_file _target_dir
                    };
                done < <(printf '%s\n' "${_ignore_list[@]}" | xargs find "$_dotfiles_dir" -type f)
            };
        fi
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
    local -r _shell_hist_files=("$HOME/.bash_history" "$HOME/.zsh_history" "$HOME/.local/share/fish/fish_history");
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
    function config::shell::hijack_gitpod_task_terminals () 
    { 
        if ! grep -q 'PROMPT_COMMAND=".*inject_tmux.*"' "$HOME/.bashrc" 2> /dev/null; then
            { 
                log::info "Setting tmux as the interactive shell for Gitpod task terminals";
                function inject_tmux () 
                { 
                    local tmux_init_lock=/tmp/.tmux.init;
                    local tmux tmux_default_shell;
                    function create_session () 
                    { 
                        tmux new-session -n home -ds main 2> /dev/null && tmux send-keys -t main:0 "cat $HOME/.dotfiles.log" Enter;
                        tmux_default_shell="$(tmux display -p '#{default-shell}')"
                    };
                    function new_window () 
                    { 
                        exec tmux new-window -n "${WINDOW_NAME:-vs:${PWD##*/}}" -t main "$@"
                    };
                    function create_window () 
                    { 
                        if test ! -e "$tmux_init_lock" && test -z "$(tmux list-clients -t main)"; then
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
                    function create_task_terms_for_ssh_in_tmux () 
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
                                        echo "$term_id:$term_name:$task_state";
                                        if test "$task_state" == "running"; then
                                            { 
                                                true
                                            };
                                        fi;
                                        unset symbol ref
                                    };
                                fi
                            };
                        done < <(gp tasks list --no-color)
                    };
                    if test "${NO_VSCODE:-false}" == "true" && test ! -e "$tmux_init_lock"; then
                        { 
                            function start_service () 
                            { 
                                local executable="$1" && shift;
                                local executable_name="${executable##*/}";
                                local args=("$@");
                                start-stop-daemon --make-pidfile --pidfile "/tmp/${executable_name}.pid" --remove-pidfile --quiet --background --start --startas "$BASH" -- -c "exec $executable ${args[*]} > /tmp/${executable_name}.log 2>&1"
                            };
                            printf '%s\n' '#!/bin/bash' '{' "$(declare -f start_service)" "start_service vimpod" "exit 0" '}' > /ide/bin/gitpod-code
                        };
                    fi;
                    touch "$tmux_init_lock";
                    if test ! -v TMUX && [ "$BASH" == /bin/bash ] || [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ]; then
                        { 
                            if test -v SSH_CONNECTION; then
                                { 
                                    exec tmux set-window-option -g -t main window-size largest\; attach
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
                                    create_window bash -c "trap 'exec $tmux_default_shell -l' EXIT; less -FXR $termout | cat; printf '%s\n' $stdin; eval $stdin;"
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
                printf '%s\n' "$(declare -f inject_tmux)" 'PROMPT_COMMAND="inject_tmux;$PROMPT_COMMAND"' >> "$HOME/.bashrc";
                sudo cp -a "$source_dir/src/utils/vimpod.py" /usr/bin/vimpod
            };
        fi
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
    function config::shell::vscode::set_tmux_as_default_shell () 
    { 
        log::info "Setting the integrated tmux shell for VScode as default";
        vscode::add_settings <<-'JSON'
{
"terminal.integrated.profiles.linux": {
"tmuxshell": {
"path": "bash",
"args": [
"-c",
"tmux new-session -ds main 2>/dev/null || :; { [ -z \"$(tmux list-clients -t main)\" ] && attach=true || for cpid in $(tmux list-clients -t main -F '#{client_pid}'); do spid=$(ps -o ppid= -p $cpid);pcomm=\"$(ps -o comm= -p $spid)\"; [[ \"$pcomm\" =~ (Code|vscode|node|supervisor) ]] && attach=false && break; done; test \"$attach\" != false && exec tmux attach -t main; }; exec tmux new-window -n \"vs:${PWD##*/}\" -t main"
]
}
},
"terminal.integrated.defaultProfile.linux": "tmuxshell"
}
JSON

    }
    function main () 
    { 
        install::system_packages & disown;
        { 
            local _private_dir="$source_dir/.private";
            local _private_dotfiles_repo="${PRIVATE_DOTFILES_REPO:-}";
            log::info "Installing local dotfiles";
            install::dotfiles "$___self_REPOSITORY" "$source_dir/raw";
            if test -n "$_private_dotfiles_repo"; then
                { 
                    log::info "Installing private dotfiles";
                    install::dotfiles "${PRIVATE_DOTFILES_REPO:-"$_private_dotfiles_repo"}" "$_private_dir" || :
                };
            fi
        };
        install::userland_tools & disown;
        if is::gitpod; then
            { 
                log::info "Gitpod environment detected!";
                config::docker_auth & disown;
                config::shell::persist_history;
                config::shell::fish::append_hist_from_gitpod_tasks & config::shell::hijack_gitpod_task_terminals & install::tmux & config::shell::vscode::set_tmux_as_default_shell & disown;
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
main@bashbox%27132 "$@";
