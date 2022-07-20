#!/usr/bin/env bash
main@bashbox%5358 () 
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
    ___MAIN_FUNCNAME="main@bashbox%5358";
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
        cp "$_target_workfile" "$_arg_path/$_script_name";
        chmod 0755 "$_arg_path/$_script_name"
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
    function dotfiles_symlink () 
    { 
        local _dotfiles_repo="${1:-"$___self_REPOSITORY"}";
        local _dotfiles_dir="${2:-$HOME/.dotfiles}";
        local _target_file _target_dir;
        local _git_output;
        if test ! -e "$_dotfiles_dir"; then
            { 
                git clone "$_dotfiles_repo" "$_dotfiles_dir" || :
            };
        fi;
        if test -e "$_dotfiles_dir"; then
            { 
                local _dotfiles_ignore="$_dotfiles_dir/.dotfilesignore";
                local _thing_path;
                local _ignore_list=(-not -path "'*/.git/*'" -not -path "'*/.dotfilesignore'" -not -path "'*/.gitpod.yml'");
                if test -e "$_dotfiles_ignore"; then
                    { 
                        while read _ignore_thing; do
                            { 
                                if [[ ! "$_ignore_thing" =~ ^\# ]]; then
                                    { 
                                        _ignore_list+=(-not -path "'$_ignore_thing'")
                                    };
                                fi
                            };
                        done < "$_dotfiles_ignore"
                    };
                fi;
                pushd "$_dotfiles_dir" > /dev/null;
                while read -r _file; do
                    { 
                        _target_file="$HOME/${_file##${_dotfiles_dir}/}";
                        _target_dir="${_target_file%/*}";
                        if test ! -d "$_target_dir"; then
                            { 
                                mkdir -p "$_target_dir"
                            };
                        fi;
                        ln -srf "$_file" "$_target_file";
                        unset _target_file _target_dir
                    };
                done < <(printf '%s\n' "${_ignore_list[@]}" | xargs find . -type f);
                popd > /dev/null
            };
        fi
    };
    function is::gitpod () 
    { 
        test -e /ide/bin/gitpod-code && test -v GITPOD_REPO_ROOT
    };
    _system_packages=(shellcheck rsync tree tmux);
    function install::system_packages () 
    { 
        log::info "Installing system packages";
        ( sudo install-packages "${_system_packages[@]}" > /dev/null ) &
    };
    function install::userland_tools () 
    { 
        log::info "Installing userland tools";
        ( curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall ) &
    };
    function docker_auth () 
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
    function shell::persist_history () 
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
                        log::warn "Overwriting $_hist with workspace persisted history file";
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
    function fish::hijack_gitpod_tasks () 
    { 
        log::info "Setting fish as the interactive shell for Gitpod task terminals";
        if ! grep 'PROMPT_COMMAND=".*exec fish"' $HOME/.bashrc > /dev/null; then
            { 
                printf '%s\n' 'PROMPT_COMMAND="[ "$BASH" == /bin/bash ] && [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ] && test -v bash_ran && exec fish || bash_ran=true;$PROMPT_COMMAND"' >> $HOME/.bashrc
            };
        fi
    };
    function fish::append_hist_from_gitpod_tasks () 
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
    function fish::inherit_bash_env () 
    { 
        local _hook_snippet="eval (~/.bprofile2fish)";
        if ! grep -q "$_hook_snippet"; then
            { 
                log::info "Injecting bash env into fish";
                printf '%s\n' "$_hook_snippet" >> "${_shell_hist_files[2]}"
            };
        fi
    };
    function tmux::setup () 
    { 
        local target="$HOME/.tmux/plugins/tpm";
        if test ! -e "$target"; then
            { 
                git clone https://github.com/tmux-plugins/tpm "$target"
            };
        fi
    };
    function ranger::setup () 
    { 
        local target=$HOME/.config/ranger;
        local devicons_activation_string="default_linemode devicons";
        if ! grep -q "$devicons_activation_string" "$target" 2> /dev/null; then
            { 
                printf '%s\n' "$devicons_activation_string" >> "$target"
            };
        fi;
        local devicons_plugin_dir="${target%/*}/plugins/ranger_devicons";
        if test ! -e "$devicons_plugin_dir"; then
            { 
                git clone https://github.com/alexanderjeurissen/ranger_devicons
            };
        fi
    };
    function main () 
    { 
        install::system_packages;
        install::userland_tools;
        { 
            local _source_dir="$(readlink -f "$0")" && _source_dir="${_source_dir%/*}";
            local _private_dir="$_source_dir/.private";
            local _private_dotfiles_repo="https://github.com/axonasif/dotfiles.private";
            log::info "Installing local dotfiles";
            dotfiles_symlink;
            log::info "Installing private dotfiles";
            dotfiles_symlink "${PRIVATE_DOTFILES_REPO:-"$_private_dotfiles_repo"}" "$_private_dir" || :
        };
        if is::gitpod; then
            { 
                log::info "Gitpod environment detected!";
                docker_auth;
                shell::persist_history;
                fish::hijack_gitpod_tasks;
                fish::append_hist_from_gitpod_tasks
            };
        fi;
        fish::inherit_bash_env;
        ranger::setup;
        tmux::setup;
        if test -n "$(jobs -p)"; then
            { 
                log::warn "Waiting for background jobs to complete"
            };
        fi
    };
    main "$@";
    wait;
    exit
}
main@bashbox%5358 "$@";
