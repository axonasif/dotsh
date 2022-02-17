#!/usr/bin/env bash
main@bashbox%9382 () 
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
    trap 'exit' USR1;
    trap 'BB_ERR_MSG="UNCAUGHT EXCEPTION" log::error "$BASH_COMMAND" || process::self::exit' ERR;
    set -eEuT -o pipefail;
    shopt -s inherit_errexit expand_aliases;
    ___self="$0";
    ___self_PID="$$";
    ___MAIN_FUNCNAME="main@bashbox%9382";
    ___self_NAME="dotfiles";
    ___self_CODENAME="dotfiles";
    ___self_AUTHORS=("AXON <axonasif@gmail.com>");
    ___self_VERSION="1.0";
    ___self_DEPENDENCIES=(std::0.2.0);
    ___self_REPOSITORY="";
    ___self_BASHBOX_COMPAT="0.3.9~";
    function bashbox_after_build () 
    { 
        local _script_name='install.sh';
        cp "$_target_workfile" "$_arg_path/$_script_name";
        chmod 0755 "$_arg_path/$_script_name"
    };
    function log::info () 
    { 
        echo -e "[%%%] \033[1;37minfo\033[0m: $@"
    };
    function log::warn () 
    { 
        echo -e "[***] \033[1;37mwarn\033[0m: $@"
    };
    function main () 
    { 
        if test -e /ide/bin/gitpod-code && test -v GITPOD_REPO_ROOT; then
            { 
                log::info "Gitpod environment detected!";
                local _source_dir="$(readlink -f "$0")" && _source_dir="${_source_dir%/*}";
                local _workspace_persist_dir="/workspace/.persist";
                local _private_dir="$_source_dir/.private";
                local _shell_hist_files=("$HOME/.bash_history" "$HOME/.local/share/fish/fish_history");
                log::info "Installing private dotfiles";
                local _target_file _target_dir _private_files;
                git clone https://github.com/axonasif/dotfiles.private "$_private_dir" && { 
                    while read -r _file; do
                        { 
                            _target_file="$HOME/${_file##${_private_dir}/}";
                            _target_dir="${_target_file%/*}";
                            if test ! -d "$_target_dir"; then
                                { 
                                    mkdir -p "$_target_dir"
                                };
                            fi;
                            ln -srf "$_file" "$_target_file";
                            unset _target_file _target_dir
                        };
                    done < <(find "$_private_dir" -type f -not -path '*/\.git/*')
                };
                curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s selfinstall;
                log::info "Persiting shell histories to /workspace";
                local _hist;
                for _hist in "${_shell_hist_files[@]}";
                do
                    { 
                        _hist_name="${_hist##*/}";
                        if test -e "$_workspace_persist_dir/$_hist_name"; then
                            { 
                                log::warn "Overwriting $_hist with workspace persisted history file";
                                ln -srf "$_workspace_persist_dir/${_hist_name}" "$_hist"
                            };
                        fi;
                        unset _hist_name
                    };
                done
            };
        fi
    };
    main "$@";
    wait;
    exit
}
main@bashbox%9382 "$@";
