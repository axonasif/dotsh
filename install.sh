#!/usr/bin/env bash
main@bashbox%22078 () 
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
    shopt -sq inherit_errexit expand_aliases nullglob;
    trap 'exit' USR1;
    trap 'BB_ERR_MSG="UNCAUGHT EXCEPTION" log::error "$BASH_COMMAND" || process::self::exit' ERR;
    ___self="$0";
    ___self_PID="$$";
    ___self_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)";
    ___MAIN_FUNCNAME='main@bashbox%22078';
    ___self_NAME="dotfiles";
    ___self_CODENAME="dotfiles";
    ___self_AUTHORS=("AXON <axonasif@gmail.com>");
    ___self_VERSION="1.0";
    ___self_DEPENDENCIES=(std::23ec8e3 https://github.com/bashbox/libtmux::fa10570);
    ___self_REPOSITORY="https://github.com/axonasif/dotfiles.git";
    ___self_BASHBOX_COMPAT="0.3.9~";
    function bashbox::build::after () 
    { 
        local _script_name='install.sh';
        local root_script="$_arg_path/$_script_name";
        cp "$_target_workfile" "$root_script";
        chmod +x "$root_script"
    };
    function bashbox::build::before () 
    { 
        local git_dir="$_arg_path/.git";
        local hooks_dir="$git_dir/hooks";
        local pre_commit_hook="$hooks_dir/pre-commit";
        if test -e "$git_dir" && test ! -e "$pre_commit_hook"; then
            { 
                log::info "Setting up pre-commit git hook";
                mkdir -p "$hooks_dir";
                printf '%s\n' '#!/usr/bin/env sh' 'bashbox build --release' 'git add install.sh' > "$pre_commit_hook";
                chmod +x "$pre_commit_hook"
            };
        fi
    };
    function livetest-min () 
    { 
        ( ___self_CONTAINER_IMAGE="axonasif/dotfiles-testing-min:latest" livetest )
    };
    function livetest () 
    { 
        ( local container_image="${CONTAINER_IMAGE:-"axonasif/dotfiles-testing-full:latest"}";
        log::info "Running bashbox build --release";
        subcommand::build --release;
        source "$_target_workdir/utils/common.sh";
        local duplicate_workspace_root="/tmp/.mrroot";
        local workspace_sources;
        if test -n "${GITPOD_REPO_ROOTS:-}"; then
            { 
                local repo_roots;
                ___self_IFS=',' read -ra workspace_sources <<< "$GITPOD_REPO_ROOTS"
            };
        else
            { 
                workspace_sources=("${_arg_path}")
            };
        fi;
        if test -e /workspace/.gitpod; then
            { 
                workspace_sources+=("/workspace/.gitpod")
            };
        fi;
        log::info "Creating a clone of ${workspace_sources} at $duplicate_workspace_root" && { 
            if command::exists rsync; then
                { 
                    mkdir -p "$duplicate_workspace_root";
                    rsync -ah --info=progress2 --delete "${workspace_sources[@]}" "$duplicate_workspace_root"
                };
            else
                { 
                    rm -rf "$duplicate_workspace_root";
                    mkdir -p "$duplicate_workspace_root";
                    cp -ra "${workspace_sources[@]}" "$duplicate_workspace_root"
                };
            fi
        };
        log::info "Starting a fake Gitpod workspace with headless IDE" && { 
            local docker_args=();
            docker_args+=(run --net=host);
            docker_args+=(-v "$duplicate_workspace_root:/workspace" -v "$_arg_path:$HOME/.dotfiles");
            if is::gitpod; then
                { 
                    docker_args+=(-v /usr/bin/gp:/usr/bin/gp:ro --privileged --device /dev/fuse -v /var/run/docker.sock:/var/run/docker.sock)
                };
            fi;
            if is::gitpod; then
                { 
                    declare gitpod_env_vars="${!GITPOD_*}" && { 
                        gitpod_env_vars="${gitpod_env_vars//"GITPOD_TASKS"/}"
                    };
                    declare gp_env_vars="${!GP_*}" && { 
                        declare key && for key in GP_PYENV_FAKEROOT GP_PYENV_INIT GP_PYENV_MIRROR;
                        do
                            { 
                                gp_env_vars="${gp_env_vars//"${key}"/}"
                            };
                        done
                    };
                    for key in ${gitpod_env_vars:-} ${gp_env_vars:-};
                    do
                        { 
                            docker_args+=(-e "${key}")
                        };
                    done;
                    docker_args+=(-e GITPOD_TASKS='[{"name":"Test foo","command":"echo This is fooooo; exit 2"},{"name":"Test boo", "command":"echo This is boooo"}]' -e DOTFILES_SPAWN_SSH_PROTO=false)
                };
            fi;
            docker_args+=(-it "$container_image");
            function startup_command () 
            { 
                export PATH="$HOME/.nix-profile/bin:$PATH";
                local logfile="$HOME/.dotfiles.log";
                local tail_cmd="tail -n +0 -F $logfile";
                eval "$(gp env -e)";
                $tail_cmd 2> /dev/null & disown;
                set +m;
                { 
                    "$HOME/.dotfiles/install.sh" 2>&1
                } > "$logfile" 2>&1 & wait;
                set -m;
                ( until tmux has-session 2> /dev/null; do
                    sleep 1;
                done;
                pkill -9 -f "${tail_cmd//+/\\+}" || :;
                tmux new-window -n ".dotfiles.log" "$tail_cmd"\; setw -g mouse on\; set -g visual-activity off;
                until test -n "$(tmux list-clients)"; do
                    sleep 1;
                done;
                printf '====== %% %s\n' "Run 'tmux detach' to exit from here" "Press 'ctrl+c' to exit the log-pager" "You can click between tabs/windows in the bottom" >> "$logfile" ) & disown;
                if test "${DOTFILES_TMUX:-true}" == true; then
                    { 
                        ___self_AWAIT_SHIM_PRINT_INDICATOR=true tmux attach
                    };
                else
                    { 
                        exec bash -li
                    };
                fi;
                if test $? != 0; then
                    { 
                        printf '%s\n' "PS1='testing-dots \w \$ '" >> "$HOME/.bashrc";
                        printf 'INFO: \n\n%s\n\n' "Falling back to debug bash shell";
                        exec bash -li
                    };
                fi
            };
            if is::gitpod; then
                { 
                    docker_args+=(/bin/bash -li)
                };
            else
                { 
                    docker_args+=(/bin/bash -li)
                };
            fi;
            local lckfile="/workspace/.dinit";
            if test -e "$lckfile" && test ! -s "$lckfile"; then
                { 
                    printf 'info: %s\n' "Waiting for the '.gitpod.yml:tasks:command' docker-pull to complete ...";
                    until test -s "$lckfile"; do
                        { 
                            sleep 0.5
                        };
                    done;
                    rm -f "$lckfile"
                };
            fi;
            docker "${docker_args[@]}" -c "$(printf "%s\n" "$(declare -f startup_command)" "startup_command")";
            docker container prune -f > /dev/null & disown
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
        [[ -n "${_snore_fd:-}" ]] || { 
            exec {_snore_fd}<> <(:)
        } 2> /dev/null || { 
            local fifo;
            fifo=$(mktemp -u);
            mkfifo -m 700 "$fifo";
            exec {_snore_fd}<> "$fifo";
            rm "$fifo"
        };
        IFS='' read ${1:+-t "$1"} -u $_snore_fd || :
    };
    function get_temp::file () 
    { 
        if test -w /tmp; then
            { 
                printf '/tmp/%s\n' ".$$_$((RANDOM * RANDOM))"
            };
        else
            if res="$(mktemp -u)"; then
                { 
                    printf '%s\n' "$res" && unset res
                };
            else
                { 
                    return 1
                };
            fi;
        fi
    };
    function get_temp::dir () 
    { 
        if test -w /tmp; then
            { 
                printf '%s\n' '/tmp'
            };
        else
            if res="$(mktemp -u)"; then
                { 
                    printf '%s\n' "${res%/*}" && unset res
                };
            else
                { 
                    return 1
                };
            fi;
        fi
    };
    function trap::stack_name () 
    { 
        local sig=${1//[^a-zA-Z0-9]/_};
        printf '__trap_stack_%s\n' "$sig"
    };
    function trap::extract () 
    { 
        printf '%s\n' "${3:-}"
    };
    function trap::get () 
    { 
        eval "trap::extract $(trap -p "$1")"
    };
    function trap::push () 
    { 
        local new_trap="$1" && shift;
        local sig;
        for sig in $*;
        do
            local stack_name="$(trap::stack_name "$sig")";
            local old_trap=$(trap::get "$sig");
            if test ! -v "$stack_name"; then
                { 
                    eval "${stack_name}=()"
                };
            fi;
            eval "${stack_name}"'[${#'"${stack_name}"'[@]}]=${old_trap:-}';
            trap "${new_trap}" "$sig";
        done
    };
    function trap::append () 
    { 
        local new_trap="$1" && shift;
        local sig;
        for sig in $*;
        do
            if [[ -z "$(trap::get "$sig")" ]]; then
                trap::push "$new_trap" "$sig";
            else
                trap::push "$(trap::get $sig) ; $new_trap" "$sig";
            fi;
        done
    };
    function lockfile () 
    { 
        local name="$1";
        local lock_file;
        lock_file="$(get_temp::dir)/.${name}.lock";
        if test -e "$lock_file"; then
            { 
                if ! { 
                    kill -0 "$(< "$lock_file")"
                }; then
                    { 
                        rm "$lock_file" 2> /dev/null || :
                    };
                fi;
                log::info "Awaiting for another ${name} job to finish"
            };
        fi;
        for _ in {1..5};
        do
            { 
                while { 
                    kill -0 "$(< "$lock_file")"
                }; do
                    { 
                        sleep 0.5
                    };
                done
            };
        done;
        until ( set -o noclobber && printf '%s\n' "$$" > "$lock_file" ); do
            { 
                sleep 0.5
            };
        done;
        trap::append "rm -f '$lock_file' 2>/dev/null" ${SIGNALS:-EXIT}
    } 2> /dev/null;
    function std::sys::info::cache_uname () 
    { 
        if test -v kernel_name; then
            { 
                return
            };
        fi;
        IFS=" " read -ra uname <<< "$(uname -srm)";
        kernel_name="${uname[0]}";
        kernel_version="${uname[1]}";
        kernel_machine="${uname[2]}";
        if [[ "$kernel_name" == "Darwin" ]]; then
            export SYSTEM_VERSION_COMPAT=0;
            IFS='
' read -d "" -ra sw_vers <<< "$(awk -F'<|>' '/key|string/ {print $3}'                             "/System/Library/CoreServices/SystemVersion.plist")";
            for ((i=0; i<${#sw_vers[@]}; i+=2))
            do
                case ${sw_vers[i]} in 
                    ProductName)
                        darwin_name=${sw_vers[i+1]}
                    ;;
                    ProductVersion)
                        osx_version=${sw_vers[i+1]}
                    ;;
                    ProductBuildVersion)
                        osx_build=${sw_vers[i+1]}
                    ;;
                esac;
            done;
        fi
    };
    function std::sys::info::cache_os () 
    { 
        if test -v os; then
            { 
                return
            };
        fi;
        std::sys::info::cache_uname;
        case $kernel_name in 
            Darwin)
                os=$darwin_name
            ;;
            SunOS)
                os=Solaris
            ;;
            Haiku)
                os=Haiku
            ;;
            MINIX)
                os=MINIX
            ;;
            AIX)
                os=AIX
            ;;
            IRIX*)
                os=IRIX
            ;;
            FreeMiNT)
                os=FreeMiNT
            ;;
            Linux | GNU*)
                os=Linux
            ;;
            *BSD | DragonFly | Bitrig)
                os=BSD
            ;;
            CYGWIN* | MSYS* | MINGW*)
                os=Windows
            ;;
            *)
                printf '%s\n' "Unknown OS detected: '$kernel_name', aborting..." 1>&2;
                printf '%s\n' "Open an issue on GitHub to add support for your OS." 1>&2;
                return 1
            ;;
        esac
    };
    function std::sys::info::os::is_android () 
    { 
        std::sys::info::cache_distro;
        [[ "${distro}" == "Android"* ]]
    };
    function std::sys::info::os::is_linux () 
    { 
        std::sys::info::cache_os;
        test "${os:-}" == "Linux"
    };
    function std::sys::info::os::is_darwin () 
    { 
        std::sys::info::cache_uname;
        [[ "${kernel_name:-}" == "Darwin"* ]]
    };
    function std::sys::info::os::is_windows () 
    { 
        std::sys::info::cache_os;
        test "${os:-}" == "Windows"
    };
    function os::is_android () 
    { 
        std::sys::info::os::is_android "$@"
    };
    function os::is_linux () 
    { 
        std::sys::info::os::is_linux "$@"
    };
    function os::is_darwin () 
    { 
        std::sys::info::os::is_darwin "$@"
    };
    function os::is_windows () 
    { 
        std::sys::info::os::is_windows "$@"
    };
    function trim_leading_trailing () 
    { 
        local _stream="${1:-}";
        local _stdin;
        if test -z "${_stream}"; then
            { 
                read -r _stdin;
                _stream="$_stdin"
            };
        fi;
        _stream="${_stream#"${_stream%%[![:space:]]*}"}";
        _stream="${_stream%"${_stream##*[![:space:]]}"}";
        printf '%s\n' "$_stream"
    };
    function trim_string () 
    { 
        : "${1#"${1%%[![:space:]]*}"}";
        : "${_%"${_##*[![:space:]]}"}";
        printf '%s\n' "$_"
    };
    function trim_all () 
    { 
        set -f;
        set -- $*;
        printf '%s\n' "$*";
        set +f
    };
    function trim_quotes () 
    { 
        : "${1//\'}";
        printf '%s\n' "${_//\"}"
    };
    function std::sys::info::cache_distro () 
    { 
        if test -v distro; then
            { 
                return
            };
        fi;
        std::sys::info::cache_os;
        : "${distro_shorthand:=on}";
        case $os in 
            Linux | BSD | MINIX)
                if [[ -f /bedrock/etc/bedrock-release && -z $BEDROCK_RESTRICT ]]; then
                    case $distro_shorthand in 
                        on | tiny)
                            distro="Bedrock Linux"
                        ;;
                        *)
                            distro=$(< /bedrock/etc/bedrock-release)
                        ;;
                    esac;
                else
                    if [[ -f /etc/redstar-release ]]; then
                        case $distro_shorthand in 
                            on | tiny)
                                distro="Red Star OS"
                            ;;
                            *)
                                distro="Red Star OS $(awk -F'[^0-9*]' '$0=$2' /etc/redstar-release)"
                            ;;
                        esac;
                    else
                        if [[ -f /etc/armbian-release ]]; then
                            . /etc/armbian-release;
                            distro="Armbian $DISTRIBUTION_CODENAME (${VERSION:-})";
                        else
                            if [[ -f /etc/siduction-version ]]; then
                                case $distro_shorthand in 
                                    on | tiny)
                                        distro=Siduction
                                    ;;
                                    *)
                                        distro="Siduction ($(lsb_release -sic))"
                                    ;;
                                esac;
                            else
                                if [[ -f /etc/mcst_version ]]; then
                                    case $distro_shorthand in 
                                        on | tiny)
                                            distro="OS Elbrus"
                                        ;;
                                        *)
                                            distro="OS Elbrus $(< /etc/mcst_version)"
                                        ;;
                                    esac;
                                else
                                    if type -p pveversion > /dev/null; then
                                        case $distro_shorthand in 
                                            on | tiny)
                                                distro="Proxmox VE"
                                            ;;
                                            *)
                                                distro=$(pveversion);
                                                distro=${distro#pve-manager/};
                                                distro="Proxmox VE ${distro%/*}"
                                            ;;
                                        esac;
                                    else
                                        if type -p lsb_release > /dev/null; then
                                            case $distro_shorthand in 
                                                on)
                                                    lsb_flags=-si
                                                ;;
                                                tiny)
                                                    lsb_flags=-si
                                                ;;
                                                *)
                                                    lsb_flags=-sd
                                                ;;
                                            esac;
                                            distro=$(lsb_release "$lsb_flags");
                                        else
                                            if [[ -f /etc/os-release || -f /usr/lib/os-release || -f /etc/openwrt_release || -f /etc/lsb-release ]]; then
                                                for file in /etc/lsb-release /usr/lib/os-release /etc/os-release /etc/openwrt_release;
                                                do
                                                    source "$file" && break;
                                                done;
                                                case $distro_shorthand in 
                                                    on)
                                                        distro="${NAME:-${DISTRIB_ID}} ${VERSION_ID:-${DISTRIB_RELEASE}}"
                                                    ;;
                                                    tiny)
                                                        distro="${NAME:-${DISTRIB_ID:-${TAILS_PRODUCT_NAME}}}"
                                                    ;;
                                                    off)
                                                        distro="${PRETTY_NAME:-${DISTRIB_DESCRIPTION}} ${UBUNTU_CODENAME}"
                                                    ;;
                                                esac;
                                            else
                                                if [[ -f /etc/GoboLinuxVersion ]]; then
                                                    case $distro_shorthand in 
                                                        on | tiny)
                                                            distro=GoboLinux
                                                        ;;
                                                        *)
                                                            distro="GoboLinux $(< /etc/GoboLinuxVersion)"
                                                        ;;
                                                    esac;
                                                else
                                                    if [[ -f /etc/SDE-VERSION ]]; then
                                                        distro="$(< /etc/SDE-VERSION)";
                                                        case $distro_shorthand in 
                                                            on | tiny)
                                                                distro="${distro% *}"
                                                            ;;
                                                        esac;
                                                    else
                                                        if type -p crux > /dev/null; then
                                                            distro=$(crux);
                                                            case $distro_shorthand in 
                                                                on)
                                                                    distro=${distro//version}
                                                                ;;
                                                                tiny)
                                                                    distro=${distro//version*}
                                                                ;;
                                                            esac;
                                                        else
                                                            if type -p tazpkg > /dev/null; then
                                                                distro="SliTaz $(< /etc/slitaz-release)";
                                                            else
                                                                if type -p kpt > /dev/null && type -p kpm > /dev/null; then
                                                                    distro=KSLinux;
                                                                else
                                                                    if [[ -d /system/app/ && -d /system/priv-app ]]; then
                                                                        distro="Android $(getprop ro.build.version.release)";
                                                                    else
                                                                        if [[ -f /etc/lsb-release && $(< /etc/lsb-release) == *CHROMEOS* ]]; then
                                                                            distro='Chrome OS';
                                                                        else
                                                                            if type -p guix > /dev/null; then
                                                                                case $distro_shorthand in 
                                                                                    on | tiny)
                                                                                        distro="Guix System"
                                                                                    ;;
                                                                                    *)
                                                                                        distro="Guix System $(guix -V | awk 'NR==1{printf $4}')"
                                                                                    ;;
                                                                                esac;
                                                                            else
                                                                                if [[ $kernel_name = OpenBSD ]]; then
                                                                                    read -ra kernel_info <<< "$(sysctl -n kern.version)";
                                                                                    distro=${kernel_info[*]:0:2};
                                                                                else
                                                                                    for release_file in /etc/*-release;
                                                                                    do
                                                                                        distro+=$(< "$release_file");
                                                                                    done;
                                                                                    if [[ -z $distro ]]; then
                                                                                        case $distro_shorthand in 
                                                                                            on | tiny)
                                                                                                distro=$kernel_name
                                                                                            ;;
                                                                                            *)
                                                                                                distro="$kernel_name $kernel_version"
                                                                                            ;;
                                                                                        esac;
                                                                                        distro=${distro/DragonFly/DragonFlyBSD};
                                                                                        [[ -f /etc/pcbsd-lang ]] && distro=PCBSD;
                                                                                        [[ -f /etc/trueos-lang ]] && distro=TrueOS;
                                                                                        [[ -f /etc/pacbsd-release ]] && distro=PacBSD;
                                                                                        [[ -f /etc/hbsd-update.conf ]] && distro=HardenedBSD;
                                                                                    fi;
                                                                                fi;
                                                                            fi;
                                                                        fi;
                                                                    fi;
                                                                fi;
                                                            fi;
                                                        fi;
                                                    fi;
                                                fi;
                                            fi;
                                        fi;
                                    fi;
                                fi;
                            fi;
                        fi;
                    fi;
                fi;
                if [[ $(< /proc/version) == *Microsoft* || $kernel_version == *Microsoft* ]]; then
                    windows_version=$(wmic.exe os get Version);
                    windows_version=$(trim_string "${windows_version/Version}");
                    case $distro_shorthand in 
                        on)
                            distro+=" [Windows $windows_version]"
                        ;;
                        tiny)
                            distro="Windows ${windows_version::2}"
                        ;;
                        *)
                            distro+=" on Windows $windows_version"
                        ;;
                    esac;
                else
                    if [[ $(< /proc/version) == *chrome-bot* || -f /dev/cros_ec ]]; then
                        [[ $distro != *Chrome* ]] && case $distro_shorthand in 
                            on)
                                distro+=" [Chrome OS]"
                            ;;
                            tiny)
                                distro="Chrome OS"
                            ;;
                            *)
                                distro+=" on Chrome OS"
                            ;;
                        esac;
                        distro=${distro## on };
                    fi;
                fi;
                distro=$(trim_quotes "$distro");
                distro=${distro/NAME=};
                if [[ $distro == "Ubuntu"* ]]; then
                    case ${XDG_CONFIG_DIRS:-} in 
                        *"studio"*)
                            distro=${distro/Ubuntu/Ubuntu Studio}
                        ;;
                        *"plasma"*)
                            distro=${distro/Ubuntu/Kubuntu}
                        ;;
                        *"mate"*)
                            distro=${distro/Ubuntu/Ubuntu MATE}
                        ;;
                        *"xubuntu"*)
                            distro=${distro/Ubuntu/Xubuntu}
                        ;;
                        *"Lubuntu"*)
                            distro=${distro/Ubuntu/Lubuntu}
                        ;;
                        *"budgie"*)
                            distro=${distro/Ubuntu/Ubuntu Budgie}
                        ;;
                        *"cinnamon"*)
                            distro=${distro/Ubuntu/Ubuntu Cinnamon}
                        ;;
                    esac;
                fi
            ;;
            "Mac OS X" | "macOS")
                case ${osx_version:-} in 
                    10.4*)
                        codename="Mac OS X Tiger"
                    ;;
                    10.5*)
                        codename="Mac OS X Leopard"
                    ;;
                    10.6*)
                        codename="Mac OS X Snow Leopard"
                    ;;
                    10.7*)
                        codename="Mac OS X Lion"
                    ;;
                    10.8*)
                        codename="OS X Mountain Lion"
                    ;;
                    10.9*)
                        codename="OS X Mavericks"
                    ;;
                    10.10*)
                        codename="OS X Yosemite"
                    ;;
                    10.11*)
                        codename="OS X El Capitan"
                    ;;
                    10.12*)
                        codename="macOS Sierra"
                    ;;
                    10.13*)
                        codename="macOS High Sierra"
                    ;;
                    10.14*)
                        codename="macOS Mojave"
                    ;;
                    10.15*)
                        codename="macOS Catalina"
                    ;;
                    10.16*)
                        codename="macOS Big Sur"
                    ;;
                    11.*)
                        codename="macOS Big Sur"
                    ;;
                    12.*)
                        codename="macOS Monterey"
                    ;;
                    *)
                        codename=macOS
                    ;;
                esac;
                distro="$codename $osx_version $osx_build";
                case $distro_shorthand in 
                    on)
                        distro=${distro/ ${osx_build}}
                    ;;
                    tiny)
                        case $osx_version in 
                            10.[4-7]*)
                                distro=${distro/${codename}/Mac OS X}
                            ;;
                            10.[8-9]* | 10.1[0-1]*)
                                distro=${distro/${codename}/OS X}
                            ;;
                            10.1[2-6]* | 11.0*)
                                distro=${distro/${codename}/macOS}
                            ;;
                        esac;
                        distro=${distro/ ${osx_build}}
                    ;;
                esac
            ;;
            "iPhone OS")
                distro="iOS $osx_version";
                os_arch=off
            ;;
            Windows)
                distro=$(wmic os get Caption);
                distro=${distro/Caption};
                distro=${distro/Microsoft }
            ;;
            Solaris)
                case $distro_shorthand in 
                    on | tiny)
                        distro=$(awk 'NR==1 {print $1,$3}' /etc/release)
                    ;;
                    *)
                        distro=$(awk 'NR==1 {print $1,$2,$3}' /etc/release)
                    ;;
                esac;
                distro=${distro/\(*}
            ;;
            Haiku)
                distro=Haiku
            ;;
            AIX)
                distro="AIX $(oslevel)"
            ;;
            IRIX)
                distro="IRIX ${kernel_version}"
            ;;
            FreeMiNT)
                distro=FreeMiNT
            ;;
        esac;
        distro=${distro//Enterprise Server};
        [[ -n $distro ]] || distro="$os (Unknown)"
    };
    function std::sys::info::distro::is_ubuntu () 
    { 
        std::sys::info::cache_distro;
        [[ "$distro" == "Ubuntu"* ]]
    };
    function distro::is_ubuntu () 
    { 
        std::sys::info::distro::is_ubuntu "$@"
    };
    function process::preserve_sudo () 
    { 
        if test "$EUID" -ne 0; then
            { 
                if ! sudo -nv 2> /dev/null; then
                    { 
                        log::warn "$___self_NAME needs root for some operations, reqesting root...";
                        sudo -v;
                        ( while sleep 30 && { 
                            kill -0 "$___self_PID"
                        } 2> /dev/null; do
                            { 
                                sudo -v
                            };
                        done ) & disown
                    };
                fi
            };
        fi
    };
    function tmux::show-option () 
    { 
        local opt="$1";
        local opt_val;
        if opt_val="$(tmux start-server\; show-option -gv "$opt")" 2> /dev/null; then
            { 
                printf '%s\n' "$opt_val"
            };
        else
            if test -v DEFAULT_VALUE; then
                { 
                    printf '%s\n' "$DEFAULT_VALUE"
                };
            else
                { 
                    return 1
                };
            fi;
        fi
    };
    function dw () 
    { 
        declare -a dw_cmd;
        if command::exists curl; then
            { 
                dw_cmd=(curl -sSL)
            };
        else
            if command::exists wget; then
                { 
                    dw_cmd=(wget -qO-)
                };
            fi;
        fi;
        if test -n "${dw_cmd:-}"; then
            { 
                declare dw_path="$1";
                declare dw_url="$2";
                declare cmd="$(
			cat <<EOF
mkdir -m 0755 -p "${dw_path%/*}" && until ${dw_cmd[*]} "$dw_url" ${PIPE:-"> '$dw_path'"}; do continue; done
if test -e "$dw_path"; then chmod +x "$dw_path"; fi
EOF
		)";
                sudo sh -c "$cmd"
            };
        else
            { 
                log::warn "curl or wget wasn't found, some things will go wrong"
            };
        fi
    };
    function is::gitpod () 
    { 
        test -e /usr/bin/gp && test -v GITPOD_REPO_ROOT
    };
    function is::codespaces () 
    { 
        test -v CODESPACES || test -e /home/codespaces
    };
    function is::cde () 
    { 
        is::gitpod || is::codespaces
    };
    function try_sudo () 
    { 
        "$@" 2> /dev/null || sudo "$@"
    };
    function get::default_shell () 
    { 
        await::signal get install_dotfiles;
        local custom_shell;
        if test "${DOTFILES_TMUX:-true}" == true; then
            { 
                await::signal get config_tmux
            };
        fi;
        if test -n "${DOTFILES_SHELL:-}"; then
            { 
                custom_shell="$(command -v "${DOTFILES_SHELL}")";
                if test "${DOTFILES_TMUX:-true}" == true; then
                    { 
                        local tmux_shell;
                        if tmux_shell="$(tmux::show-option default-shell)" && [ "$tmux_shell" != "$custom_shell" ]; then
                            { 
                                ( exec 1>&-;
                                until tmux has-session 2> /dev/null; do
                                    { 
                                        sleep 1
                                    };
                                done;
                                tmux set -g default-shell "$custom_shell" || : ) & disown
                            };
                        fi
                    };
                fi
            };
        else
            if test "${DOTFILES_TMUX:-true}" == true; then
                { 
                    if custom_shell="$(tmux::show-option default-shell)" && [ "${custom_shell}" == "/bin/sh" ]; then
                        { 
                            custom_shell="$(command -v bash)"
                        };
                    fi
                };
            else
                if ! custom_shell="$(command -v fish)"; then
                    { 
                        custom_shell="$(command -v bash)"
                    };
                fi;
            fi;
        fi;
        printf '%s\n' "${custom_shell:-/bin/bash}"
    };
    function command::exists () 
    { 
        declare cmd="$1";
        cmd="$(command -v "$cmd")" && test -x "$cmd"
    };
    function vscode::add_settings () 
    { 
        SIGNALS="RETURN ERR EXIT" lockfile "vscode_addsettings";
        await::until_true command::exists yq;
        read -t0.5 -u0 -r -d '' input || :;
        if test -z "${input:-}"; then
            { 
                return 1
            };
        fi;
        local settings_file;
        for settings_file in "$@";
        do
            { 
                local tmp_file="${settings_file%/*}/.tmp$$";
                if test ! -e "$settings_file"; then
                    { 
                        mkdir -p "${settings_file%/*}";
                        touch "$settings_file"
                    };
                fi;
                if test ! -s "$settings_file" || ! yq -o=json -reM '""' "$settings_file" > /dev/null 2>&1; then
                    { 
                        printf '%s\n' "$input" > "$settings_file"
                    };
                else
                    { 
                        cp -a "$settings_file" "$tmp_file";
                        yq ea -o=json -I2 -M '. as $item ireduce ({}; . * $item )' - "$tmp_file" <<< "$input" > "$settings_file";
                        rm -f "$tmp_file"
                    };
                fi
            };
        done
    };
    function dotfiles::initialize () 
    { 
        await::until_true command::exists git;
        local installation_target="${INSTALL_TARGET:-"$HOME"}";
        local last_applied_filelist="$installation_target/.last_applied_dotfiles";
        local dotfiles_repo local_dotfiles_repo_count repo_user repo_name source_dir repo_dir_name check_dir;
        mkdir -p "$dotfiles_sh_repos_dir";
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
                done < "$last_applied_filelist";
                printf '' > "$last_applied_filelist"
            };
        fi;
        for dotfiles_repo in "$@";
        do
            { 
                if ! [[ "$dotfiles_repo" =~ (https?|git):// ]]; then
                    { 
                        : "$dotfiles_repo"
                    };
                else
                    { 
                        repo_user="${dotfiles_repo%/*}" && repo_user="${repo_user##*/}";
                        repo_name="${dotfiles_repo##*/}";
                        repo_dir_name="--${repo_user}_${repo_name}";
                        check_dir=("$dotfiles_sh_repos_dir"/*"$repo_dir_name");
                        if test -n "${check_dir:-}"; then
                            { 
                                : "${check_dir[0]}"
                            };
                        else
                            { 
                                local_dotfiles_repo_count=("$dotfiles_sh_repos_dir"/*);
                                local_dotfiles_repo_count="${#local_dotfiles_repo_count[*]}";
                                : "${dotfiles_sh_repos_dir}/$(( local_dotfiles_repo_count + 1 ))${repo_dir_name}"
                            };
                        fi
                    };
                fi;
                local source_dir="${SOURCE_DIR:-"$_"}";
                if test ! -e "${source_dir}"; then
                    { 
                        rm -rf "$source_dir";
                        git clone --filter=tree:0 "$dotfiles_repo" "$source_dir" > /dev/null 2>&1 || :
                    };
                fi;
                if test -e "$source_dir"; then
                    { 
                        local _dotfiles_ignore="$source_dir/.dotfilesignore";
                        local _thing_path;
                        local _ignore_list=(-not -path '*/.git/*' -not -path '*/.dotfilesignore' -not -path '*/.gitpod*' -not -path '*/README.md' -not -path "$source_dir/src/*" -not -path "$source_dir/target/*" -not -path "$source_dir/Bashbox.meta" -not -path "$source_dir/install.sh");
                        if test -e "$_dotfiles_ignore"; then
                            { 
                                while read -r _ignore_thing; do
                                    { 
                                        if [[ ! "$_ignore_thing" =~ ^\# ]]; then
                                            { 
                                                _ignore_thing="$source_dir/${_ignore_thing}";
                                                _ignore_thing="${_ignore_thing//\/\//\/}";
                                                _ignore_list+=(-not -path "$_ignore_thing")
                                            };
                                        fi;
                                        unset _ignore_thing
                                    };
                                done < "$_dotfiles_ignore"
                            };
                        fi;
                        local target_file target_dir;
                        while read -r _file; do
                            { 
                                file_name="${_file#"${source_dir}"/}";
                                target_file="$installation_target/${file_name}";
                                target_dir="${target_file%/*}";
                                if test -e "$target_file" && { 
                                    if test -L "$target_file"; then
                                        { 
                                            test "$(readlink "$target_file")" != "$_file"
                                        };
                                    fi
                                }; then
                                    { 
                                        case "$file_name" in 
                                            ".bashrc" | ".zshrc" | ".kshrc" | ".profile")
                                                log::info "Your $file_name is being injected into the existing host $target_file";
                                                local check_str="if test -e '$_file'; then source '$_file'; fi";
                                                if ! grep -q "$check_str" "$target_file"; then
                                                    { 
                                                        printf '%s\n' "$check_str" >> "$target_file"
                                                    };
                                                fi;
                                                continue
                                            ;;
                                            ".gitconfig")
                                                log::info "Your $file_name is being injected into the existing host $file_name";
                                                local check_str="    path = $_file";
                                                if ! grep -q "$check_str" "$target_file" 2> /dev/null; then
                                                    { 
                                                        { 
                                                            printf '[%s]\n' 'include';
                                                            printf '%s\n' "$check_str"
                                                        } >> "$target_file"
                                                    };
                                                fi;
                                                continue
                                            ;;
                                        esac
                                    };
                                fi;
                                if test ! -d "$target_dir"; then
                                    { 
                                        mkdir -p "$target_dir"
                                    };
                                fi;
                                ln -sf "$_file" "$target_file";
                                printf '%s\n' "$target_file" >> "$last_applied_filelist";
                                unset target_file target_dir
                            };
                        done < <(find "$source_dir" -type f "${_ignore_list[@]}")
                    };
                fi
            };
        done
    };
    function await::until_true () 
    { 
        local time="${TIME:-0.5}";
        local input=("$@");
        until "${input[@]}"; do
            { 
                sleep "$time"
            };
        done
    };
    function await::while_true () 
    { 
        local time="${TIME:-0.5}";
        local input=("$@");
        while "${input[@]}"; do
            { 
                sleep "$time"
            };
        done
    };
    function await::for_file_existence () 
    { 
        local file="$1";
        await::until_true test -e "$file"
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
    function await::for_vscode_ide_start () 
    { 
        if grep -q 'supervisor' /proc/1/cmdline; then
            { 
                gp ports await 23000 > /dev/null
            };
        fi
    };
    function await::create_shim () 
    { 
        declare -a vars_to_unset=(SHIM_MIRROR SHIM_SOURCE KEEP_internal_call);
        declare +x CLOSE KEEP DIRECT_CMD;
        export SHIM_MIRROR;
        declare SHIM_HEADER_SIGNATURE="# AWAIT_CREATE_SHIM";
        function is::custom_shim () 
        { 
            test -v SHIM_MIRROR
        };
        function revert_shim () 
        { 
            if test -e "$shim_source"; then
                { 
                    try_sudo touch "$shim_tombstone";
                    if ! is::custom_shim; then
                        { 
                            try_sudo ln -sf "$shim_source" "$target"
                        };
                    else
                        { 
                            try_sudo ln -sf "$shim_source" "$target"
                        };
                    fi;
                    unset "${vars_to_unset[@]}";
                    unset -f "$target_name";
                    export PATH="${PATH//"${shim_dir}:"/}";
                    ( sleep 3;
                    try_sudo rm -f "$shim_tombstone" || true ) & disown
                };
            fi
        };
        function create_self () 
        { 
            declare +x NO_PRINT;
            function cmd () 
            { 
                printf '%s\n' '#!/usr/bin/env bash' "$SHIM_HEADER_SIGNATURE" "$(declare -f main)" 'main "$@"'
            };
            if ! test -v NO_PRINT; then
                { 
                    cmd > "${1:-"${BASH_SOURCE[0]}"}"
                };
            else
                { 
                    cmd
                };
            fi
        };
        declare shim_dir shim_source shim_tombstone target="$1";
        declare target_name="${target##*/}";
        if ! is::custom_shim; then
            { 
                shim_dir="${target%/*}/.ashim";
                shim_source="${shim_dir}/${target##*/}"
            };
        else
            { 
                shim_dir="${SHIM_MIRROR%/*}/.cshim";
                shim_source="$shim_dir/${SHIM_MIRROR##*/}"
            };
        fi;
        shim_tombstone="${shim_source}.tombstone";
        if test -v CLOSE; then
            { 
                revert_shim;
                return
            };
        fi;
        if test -v KEEP && test ! -v KEEP_internal_call; then
            { 
                export SHIM_SOURCE="$shim_source";
                export KEEP_internal_call=true
            };
        fi;
        if test -v DIRECT_CMD; then
            { 
                if shift; then
                    { 
                        ( unset "${vars_to_unset[@]}";
                        "$@" )
                    };
                fi;
                return
            };
        fi;
        if test ! -v NOCLOBBER; then
            { 
                if test -e "$target" && ! is::custom_shim; then
                    { 
                        try_sudo mkdir -p "$shim_dir";
                        try_sudo mv "$target" "$shim_source"
                    };
                else
                    if test -e "${SHIM_MIRROR:-}" && is::custom_shim; then
                        { 
                            try_sudo mkdir -p "$shim_dir";
                            try_sudo mv "$SHIM_MIRROR" "$shim_source"
                        };
                    fi;
                fi
            };
        else
            if test -v NOCLOBBER && { 
                test -e "$target" || test -e "${SHIM_MIRROR:-}"
            }; then
                { 
                    log::warn "${FUNCNAME[0]}: $target already exists";
                    return 0
                };
            fi;
        fi;
        declare USER && USER="$(id -u -n)";
        try_sudo sh -c "mkdir -p \"${target%/*}\" && touch \"$target\" && chown $USER:$USER \"$target\"";
        function async_wrapper () 
        { 
            set -eu;
            function await_nowrite_executable () 
            { 
                declare input="$1";
                while lsof -F 'f' -- "$input" 2> /dev/null | grep -q '^f.*w$'; do
                    sleep 0.5;
                done;
                await::until_true test -x "$input"
            };
            function await_nowrite_executable_symlink () 
            { 
                declare input="$1";
                await_nowrite_executable "$input";
                await::until_true test -L "$input"
            };
            function exec_bin () 
            { 
                local args=("$@");
                local bin="${args[0]}";
                await::until_true test -x "$bin";
                unset "${vars_to_unset[@]}";
                export PATH="${bin%/*}:$PATH";
                exec "${args[@]}"
            };
            function await_while_shim_exists () 
            { 
                if is::custom_shim; then
                    { 
                        : "$target"
                    };
                else
                    { 
                        : "$shim_source"
                    };
                fi;
                local checkf="$_";
                for _i in {1..3};
                do
                    { 
                        sleep 0.2${RANDOM};
                        while test -e "$checkf" && test ! -L "$checkf"; do
                            sleep 0.5${RANDOM};
                        done
                    };
                done
            };
            if test -v AWAIT_SHIM_PRINT_INDICATOR; then
                { 
                    printf 'info[shim]: Loading %s\n' "$target"
                };
            fi;
            if test -e "$shim_source"; then
                { 
                    if test "${KEEP_internal_call:-}" == true; then
                        { 
                            exec_bin "$shim_source" "$@"
                        };
                    else
                        { 
                            await_while_shim_exists
                        };
                    fi
                };
            else
                if ! is::custom_shim; then
                    { 
                        while test "$(sed -n '2p;3q' "$target" 2>/dev/null)" == "$SHIM_HEADER_SIGNATURE"; do
                            { 
                                sleep 0.5
                            };
                        done;
                        await_nowrite_executable "$target"
                    };
                else
                    { 
                        if test "${KEEP_internal_call:-}" == true; then
                            { 
                                await_nowrite_executable "$SHIM_MIRROR"
                            };
                        else
                            { 
                                await_nowrite_executable_symlink "$target"
                            };
                        fi
                    };
                fi;
            fi;
            if test -v KEEP_internal_call; then
                { 
                    if test "${KEEP_internal_call:-}" == true; then
                        { 
                            if test ! -e "$shim_tombstone" && test ! -e "$shim_source"; then
                                { 
                                    try_sudo mkdir -p "${shim_dir}";
                                    if ! is::custom_shim; then
                                        { 
                                            try_sudo mv "$target" "$shim_source";
                                            try_sudo env self="$(NO_PRINT=true create_self)" target="$target" sh -c 'printf "%s\n" "$self" > "$target" && chmod +x $target'
                                        };
                                    else
                                        { 
                                            try_sudo mv "${SHIM_MIRROR}" "$shim_source"
                                        };
                                    fi
                                };
                            fi;
                            if test -e "$shim_source"; then
                                { 
                                    exec_bin "$shim_source" "$@"
                                };
                            fi
                        };
                    else
                        { 
                            await_while_shim_exists
                        };
                    fi
                };
            fi;
            exec_bin "$target" "$@"
        };
        { 
            printf 'function main() {\n';
            printf '%s="%s"\n' target "$target" shim_source "$shim_source" shim_dir "$shim_dir" SHIM_HEADER_SIGNATURE "$SHIM_HEADER_SIGNATURE";
            printf '%s=(%s)\n' vars_to_unset "${vars_to_unset[*]}";
            if test -v SHIM_MIRROR; then
                { 
                    printf '%s="%s"\n' SHIM_MIRROR "$SHIM_MIRROR"
                };
            fi;
            if test -v KEEP; then
                { 
                    printf '%s="%s"\n' "KEEP_internal_call" '${KEEP_internal_call:-false}' shim_tombstone "$shim_tombstone"
                };
            fi;
            printf '%s\n' "$(declare -f await::while_true await::until_true await::for_file_existence sleep is::custom_shim try_sudo create_self async_wrapper)";
            printf '%s\n' 'async_wrapper "$@"; }'
        } > "$target";
        ( source "$target";
        create_self "$target" );
        chmod +x "$target"
    };
    function install::packages () 
    { 
        if test "${DOTFILES_TMUX:-true}" == true; then
            { 
                if is::cde; then
                    { 
                        ( dw "/usr/bin/.dw/tmux" "https://github.com/axonasif/build-static-tmux/releases/latest/download/tmux.linux-amd64.stripped" & disown;
                        if ! command::exists yq; then
                            { 
                                PIPE="| tar -O -xpz > /usr/bin/yq" dw /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.30.2/yq_linux_amd64.tar.gz" & disown
                            };
                        fi;
                        if ! command::exists jq; then
                            { 
                                dw /usr/bin/jq "https://github.com/stedolan/jq/releases/latest/download/jq-linux64" & disown
                            };
                        fi ) & disown
                    };
                else
                    { 
                        nixpkgs_level_1+=(nixpkgs.tmux nixpkgs.yq nixpkgs.jq)
                    };
                fi
            };
        fi;
        nixpkgs_level_1+=(nixpkgs."${DOTFILES_SHELL:-fish}");
        case "${DOTFILES_EDITOR:-neovim}" in 
            "emacs")
                nixpkgs_level_2+=("nixpkgs.emacs")
            ;;
            "helix")
                nixpkgs_level_2+=("nixpkgs.helix")
            ;;
            "neovim")
                if is::cde; then
                    { 
                        PIPE="| tar --strip-components=1 -C /usr -xpz" dw /usr/bin/nvim "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz" & disown
                    };
                else
                    { 
                        nixpkgs_level_2+=("nixpkgs-unstable.neovim")
                    };
                fi
            ;;
        esac;
        if ! command::exists git; then
            { 
                nixpkgs_level_2+=(nixpkgs.git)
            };
        fi;
        if is::gitpod; then
            { 
                nixpkgs_level_2+=(nixpkgs."${gitpod_scm_cli}")
            };
        else
            { 
                nixpkgs_level_2+=(nixpkgs.gh nixpkgs.glab)
            };
        fi;
        if os::is_darwin; then
            { 
                if test ! -e /opt/homebrew/Library/Taps/homebrew/homebrew-core/.git && test ! -e /usr/local/Library/Taps/homebrew/homebrew-core/.git; then
                    { 
                        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    };
                fi;
                log::info "Installing userland packages with brew";
                if ! command::exists brew; then
                    { 
                        PATH="$PATH:/opt/homebrew/bin:/usr/local/bin";
                        eval "$(brew shellenv)"
                    };
                fi;
                for level in ${!brewpkgs_level_*};
                do
                    { 
                        declare -n ref="$level";
                        if test -n "${ref:-}"; then
                            { 
                                NONINTERACTIVE=1 brew install -q "${ref[@]}" || true
                            };
                        fi
                    };
                done
            };
        fi;
        if command::exists apt; then
            { 
                log::info "Installing ubuntu system packages";
                ( sudo apt-get update;
                sudo debconf-set-selections <<< 'debconf debconf/frontend select Noninteractive';
                for level in ${!aptpkgs_level_*};
                do
                    { 
                        declare -n ref="$level";
                        if test -n "${ref:-}"; then
                            { 
                                sudo apt-get install -yq --no-install-recommends "${ref[@]}"
                            };
                        fi
                    };
                done;
                sudo debconf-set-selections <<< 'debconf debconf/frontend select Readline' ) > /dev/null & disown
            };
        fi;
        log::info "Installing userland packages with nix";
        ( USER="$(id -u -n)" && export USER;
        if test ! -e /nix; then
            { 
                sudo sh -c "mkdir -p /nix && chown -R $USER:$USER /nix";
                log::info "Installing nix";
                curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon > /dev/null 2>&1
            };
        fi;
        source "$HOME/.nix-profile/etc/profile.d/nix.sh" 2> /dev/null || source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh;
        function nix-install () 
        { 
            if test ! -v nix_unstable_installed && [[ "$*" == *nixpkgs-unstable.* ]]; then
                { 
                    nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable;
                    nix-channel --update;
                    nix_unstable_installed=true
                };
            fi;
            command nix-env -iAP "$@" 2>&1 | grep --line-buffered -vE '^(copying|building|generating|  /nix/store|these|this path will be fetched)'
        };
        for level in ${!nixpkgs_level_*};
        do
            { 
                declare -n ref="$level";
                if test -n "${ref:-}"; then
                    { 
                        nix-install "${ref[@]}"
                    };
                fi
            };
        done ) & disown
    };
    function install::misc () 
    { 
        log::info "Installing misc tools";
        ( curl --proto '=https' --tlsv1.2 -sSfL "https://git.io/Jc9bH" | bash -s -- selfinstall --no-modify-path > /dev/null 2>&1;
        if test -e "$HOME/.bashrc.d"; then
            { 
                : ".bashrc.d"
            };
        else
            if test -e "$HOME/.shellrc.d"; then
                { 
                    : ".shellrc.d"
                };
            else
                { 
                    exit 0
                };
            fi;
        fi;
        target="$HOME/$_/bashbox.bash";
        rm -f "$target";
        printf 'source %s\n' "$HOME/.bashbox/env" > "$target" ) & disown
    };
    function install::ranger () 
    { 
        if ! command::exists pip3; then
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
    function install::dotfiles () 
    { 
        log::info "Installing dotfiles";
        TARGET="$HOME" dotfiles::initialize "${dotfiles_repos[@]}";
        await::signal send install_dotfiles
    };
    function install::filesync () 
    { 
        if is::cde; then
            { 
                log::info "Performing local filesync, scoped to ${HOSTNAME:-"${GITPOD_WORKSPACE_ID:-}"} workspace";
                if test -e "$workspace_persist_dir"; then
                    { 
                        TARGET="$workspace_persist_dir" filesync::restore_local
                    };
                else
                    { 
                        TARGET="$workspace_persist_dir" filesync::save_local "${files_to_persist_locally[@]}"
                    };
                fi
            };
        fi;
        if test -n "${RCLONE_DATA:-}"; then
            { 
                mkdir -p "${rclone_conf_file%/*}";
                printf '%s\n' "${RCLONE_DATA}" | base64 -d > "$rclone_conf_file";
                await::until_true command::exists rclone;
                log::info "Performing cloud filesync, scoped globally";
                mkdir -p "${rclone_mount_dir}";
                sudo "$(command -v rclone)" "${rclone_cmd_args[@]}" & disown;
                declare rclone_dotfiles_sh_dir="$rclone_mount_dir/.dotfiles-sh";
                declare rclone_dotfiles_sh_sync_dir="$rclone_dotfiles_sh_dir/sync";
                declare rclone_dotfiles_sh_sync_relative_home_dir="$rclone_dotfiles_sh_sync_dir/relhome";
                declare rclone_dotfiles_sh_sync_rootfs_dir="$rclone_dotfiles_sh_sync_dir/rootfs";
                declare times=0;
                until test -e "$rclone_dotfiles_sh_dir"; do
                    { 
                        sleep 1;
                        if test $times -gt 10; then
                            { 
                                break
                            };
                        fi;
                        ((times=times+1))
                    };
                done;
                if test -e "$rclone_dotfiles_sh_sync_relative_home_dir"; then
                    { 
                        TARGET="$HOME" dotfiles::initialize "$rclone_dotfiles_sh_sync_relative_home_dir"
                    };
                fi;
                if test -e "$rclone_dotfiles_sh_sync_rootfs_dir"; then
                    { 
                        TARGET="$rclone_dotfiles_sh_sync_rootfs_dir" filesync::restore_local
                    };
                fi
            };
        fi
    };
    function filesync::restore_local () 
    { 
        declare +x TARGET;
        declare target_persist_dir="${TARGET}";
        mkdir -p "$target_persist_dir";
        declare _input _persisted_node _persisted_node_dir;
        while read -r _input; do
            { 
                _persisted_node="${_input#"${target_persist_dir}"}";
                _persisted_node_dir="${_persisted_node%/*}";
                if test -e "$_persisted_node"; then
                    { 
                        log::info "Overwriting ${_input} with workspace persisted file";
                        try_sudo mkdir -p "${_input%/*}";
                        try_sudo ln -sf "$_persisted_node" "$_input"
                    };
                fi
            };
        done < <(find "$target_persist_dir" -type f)
    };
    function filesync::save_local () 
    { 
        declare +x TARGET;
        declare target_persist_dir="${TARGET}";
        mkdir -p "$target_persist_dir";
        declare _input _input_dir _persisted_node _persisted_node_dir;
        for _input in "$@";
        do
            { 
                if test ! -v RELATIVE_HOME; then
                    { 
                        _persisted_node="${target_persist_dir}/${_input}";
                        _persisted_node_dir="${_persisted_node%/*}";
                        _input_dir="${_input%/*}"
                    };
                else
                    { 
                        _persisted_node="${target_persist_dir}/${_input#"$HOME"}";
                        _persisted_node_dir="${_persisted_node%/*}";
                        _input_dir="${_input%/*}"
                    };
                fi;
                if test "$_input_dir" == "$_input"; then
                    { 
                        log::error "Something went wrong, _input_dir is same as _input" 1 || return
                    };
                fi;
                if test ! -e "$_persisted_node"; then
                    { 
                        try_sudo mkdir -p "$_persisted_node_dir";
                        if test ! -e "$_input" && test ! -d "$_input"; then
                            { 
                                try_sudo sh -c "mkdir -p \"$_input_dir\" && printf '' > \"$_input\""
                            };
                        fi;
                        try_sudo cp -ra "$_input" "$_persisted_node_dir";
                        try_sudo rm -rf "$_input";
                        try_sudo ln -sr "$_persisted_node" "$_input"
                    };
                else
                    { 
                        log::warn "$_input is already persisted"
                    };
                fi
            };
        done
    };
    function filesync::cli () 
    { 
        function cli::save () 
        { 
            case "$1" in 
                -h | --help)
                    printf '%s\t%s\n' "-rh" "Save in global home" "-h|--help" "This help message";
                    exit
                ;;
                -dh | --dynamic-home)
                    declare arg_rel_home=true;
                    shift
                ;;
            esac;
            declare file filelist;
            for file in "$@";
            do
                { 
                    filelist+=("$(readlink "$file")") || true
                };
            done;
            if test ! -v arg_rel_home; then
                { 
                    filesync::save_local "${filelist[@]}"
                };
            else
                { 
                    RELATIVE_HOME="$arg_rel_home" filesync::save_local "${filelist[@]}"
                };
            fi
        };
        case "$1" in 
            "filesync")
                shift
            ;;
            *)
                return
            ;;
        esac;
        case "$1" in 
            -h | --help)
                printf '%s\t%s\n' "save" "Start syncing selected files" "restore" "Manual file sync trigger" "-h|--help" "This help message"
            ;;
            save)
                shift;
                cli::save "$@"
            ;;
            restore)
                shift;
                cli::restore "$@"
            ;;
        esac;
        exit
    };
    readonly RC='\033[0m' RED='\033[0;31m' BRED='\033[1;31m' GRAY='\033[1;30m';
    readonly BLUE='\033[0;34m' BBLUE='\033[1;34m' CYAN='\033[0;34m' BCYAN='\033[1;34m';
    readonly WHITE='\033[1;37m' GREEN='\033[0;32m' BGREEN='\033[1;32m' YELLOW='\033[1;33m';
    readonly PURPLE='\033[0;35m' BPURPLE='\033[1;35m' ORANGE='\033[0;33m';
    function tmux::new-session () 
    { 
        declare +x WINDOW_NAME SESSION_NAME;
        tmux new-session -n "${WINDOW_NAME:-home}" -ds "$SESSION_NAME" "$@"
    };
    function await::until_tmux_has-session () 
    { 
        until tmux has-session 2> /dev/null; do
            { 
                sleep 0.5
            };
        done
    };
    function tmux::new-window () 
    { 
        declare +x WINDOW_NAME SESSION_NAME;
        tmux new-window -n "${WINDOW_NAME:-"${PWD##*/}"}" -t "${SESSION_NAME}" "$@"
    };
    function tmux_create_session () 
    { 
        SESSION_NAME="$tmux_first_session_name" WINDOW_NAME="editor" tmux::new-session -c "${GITPOD_REPO_ROOT:-$HOME}" -- "$(get::default_shell)" -li 2> /dev/null || :
    };
    function tmux_create_window () 
    { 
        SESSION_NAME="$tmux_first_session_name" tmux::new-window "$@"
    };
    function tmux::start_vimpod () 
    { 
        if ! ( set -o noclobber && printf '' > /tmp/.dotsh_spawn_ssh ) 2> /dev/null; then
            { 
                return
            };
        fi;
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
    function get::task_cmd () 
    { 
        local task="$1";
        local cmdc;
        local cmdc_tmp_file="/tmp/.dotfiles_task_cmd.$((RANDOM * $$))";
        IFS='' read -rd '' cmdc <<CMDC || 
function ___exit_callback() {
	local r=\$?;
	rm -f "$cmdc_tmp_file" 2>/dev/null || true;
	if test -z "\${___manual_exit:-}"; then {
		exec '$(get::default_shell)' -il;
	} else {
		printf "\n${BRED}>> This task issued manual 'exit' with return code \$r${RC}\n";
		printf "${BRED}>> Press Enter or Return to dismiss${RC}" && read -r -n 1;
	} fi
}
function exit() {
	___manual_exit=true;
	command exit "\$@";
}; export -f exit;
trap "___exit_callback" EXIT;
printf "$BGREEN>> Executing task in bash:$RC\n";
IFS='' read -rd '' lines <<'EOF' || :;
$task
EOF
printf '%s\n' "\$lines" | while IFS='' read -r line; do
	printf "    ${YELLOW}%s${RC}\n" "\$line";
done
# printf '\n';
$task
CMDC
 :
        if test "${#cmdc}" -gt 4096; then
            { 
                printf '%s\n' "$cmdc" > "$cmdc_tmp_file";
                cmdc="$(
			printf 'eval "$(< "%s")"\n' "$cmdc_tmp_file";
		)"
            };
        fi;
        printf '%s\n' "$cmdc"
    };
    function config::tmux::hijack_gitpod_task_terminals () 
    { 
        function tmux::inject () 
        { 
            if [ "$BASH" == /bin/bash ] || [ "$PPID" == "$(pgrep -f "supervisor run" | head -n1)" ]; then
                { 
                    if test -v TMUX; then
                        { 
                            return
                        };
                    fi;
                    if test "${DOTFILES_TMUX:-true}" == true; then
                        { 
                            if test -v SSH_CONNECTION; then
                                { 
                                    if test "${DOTFILES_NO_VSCODE:-false}" == "true"; then
                                        { 
                                            pkill -9 vimpod || :
                                        };
                                    fi;
                                    AWAIT_SHIM_PRINT_INDICATOR=true tmux_create_session;
                                    exec tmux set -g -t "${tmux_first_session_name}" window-size largest\; attach \; attach -t :${tmux_first_window_num}
                                };
                            else
                                { 
                                    exit 0
                                };
                            fi
                        };
                    else
                        { 
                            local stdin cmd;
                            IFS= read -t0.01 -u0 -r -d '' stdin;
                            if test -n "$stdin"; then
                                { 
                                    cmd="$(get::task_cmd)";
                                    exec bash -lic "$cmd"
                                };
                            fi
                        };
                    fi
                };
            fi
        };
        if ! grep -q 'PROMPT_COMMAND=".*tmux::inject.*"' "$HOME/.bashrc" 2> /dev/null; then
            { 
                local function_exports=(tmux::new-session tmux_create_session tmux::inject get::task_cmd tmux::show-option get::default_shell await::signal);
                printf '%s\n' "tmux_first_session_name=$tmux_first_session_name" "tmux_first_window_num=$tmux_first_window_num" "$(declare -f "${function_exports[@]}")" 'PROMPT_COMMAND="tmux::inject; $PROMPT_COMMAND"' >> "$HOME/.bashrc"
            };
        fi
    };
    function config::tmux () 
    { 
        if test "${DOTFILES_TMUX:-true}" != true; then
            { 
                await::signal send config_tmux;
                return
            };
        fi;
        log::info "Setting up tmux";
        if is::cde; then
            { 
                declare tmux_exec_path=/usr/bin/tmux;
                KEEP=true SHIM_MIRROR="/usr/bin/.dw/tmux" await::create_shim "$tmux_exec_path"
            };
        else
            { 
                await::until_true command::exists tmux
            };
        fi;
        if is::gitpod; then
            { 
                if test "${DOTFILES_SPAWN_SSH_PROTO:-true}" == true; then
                    { 
                        tmux::start_vimpod & disown
                    };
                fi;
                config::tmux::hijack_gitpod_task_terminals & wait
            };
        fi;
        { 
            await::signal get install_dotfiles;
            local target="$HOME/.tmux/plugins/tpm";
            if test ! -e "$target"; then
                { 
                    git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target" > /dev/null 2>&1
                };
            fi;
            "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh";
            await::signal send config_tmux;
            if is::cde; then
                { 
                    tmux_create_session
                };
            fi;
            CLOSE=true await::create_shim "${tmux_exec_path:-}";
            ( if is::gitpod; then
                { 
                    await::until_true command::exists yq;
                    if test -v DOTFILES_READ_GITPOD_YML; then
                        { 
                            declare gitpod_yml=("${GITPOD_REPO_ROOT:-}/".gitpod.y*ml);
                            if test -n "${gitpod_yml:-}" && gitpod_yml="${gitpod_yml[0]}" && test -e "$gitpod_yml"; then
                                { 
                                    if ! GITPOD_TASKS="$(yq -I0 -erM -o=json '.tasks' "$gitpod_yml" 2>&1)"; then
                                        { 
                                            log::error "Syntax errors found on $gitpod_yml: $GITPOD_TASKS" 1 || return
                                        };
                                    fi
                                };
                            fi
                        };
                    fi;
                    if test -z "${GITPOD_TASKS:-}"; then
                        { 
                            return
                        };
                    else
                        { 
                            log::info "Spawning Gitpod tasks in tmux"
                        };
                    fi
                };
            else
                if is::codespaces && test -e "${CODESPACES_VSCODE_FOLDER:-}"; then
                    { 
                        cd "$CODESPACE_VSCODE_FOLDER" || true;
                        return
                    };
                else
                    { 
                        return
                    };
                fi;
            fi;
            await::for_file_existence "$workspace_dir/.gitpod/ready";
            cd "${GITPOD_REPO_ROOT:-}";
            function jqw () 
            { 
                local cmd;
                if cmd=$(yq -I0 -erM "$@" <<<"$GITPOD_TASKS"); then
                    { 
                        printf '%s\n' "$cmd"
                    };
                else
                    { 
                        return 1
                    };
                fi
            } 2> /dev/null;
            local name cmd arr_elem=0;
            local cmd_tmp_file="/tmp/.tmux_gpt_cmd";
            while { 
                success=0;
                cmd_prebuild="$(jqw ".[${arr_elem}] | [.init] | map(select(. != null)) | .[]")" && ((success=success+1));
                cmd_others="$(jqw ".[${arr_elem}] | [.before, .command] | map(select(. != null)) | .[]")" && ((success=success+1));
                test $success -gt 0
            }; do
                { 
                    if ! name="$(jqw ".[${arr_elem}].name")"; then
                        { 
                            name="AnonTask-${arr_elem}"
                        };
                    fi;
                    local prebuild_log="$workspace_dir/.gitpod/prebuild-log-${arr_elem}";
                    cmd="$(
					if test -e "$prebuild_log"; then {
						printf 'cat %s\n' "$prebuild_log";
						printf '%s\n' "${cmd_others:-}";
					} else {
						printf '%s\n' "${cmd_prebuild:-}" "${cmd_others:-}";
					} fi
				)";
                    cmd="$(get::task_cmd "$cmd")";
                    WINDOW_NAME="$name" tmux_create_window -d -- bash -lic "$cmd";
                    ((arr_elem=arr_elem+1))
                };
            done ) & disown;
            await::signal send config_tmux_session;
            if is::gitpod; then
                { 
                    local spinner="/usr/bin/tmux-dotfiles-spinner.sh";
                    local spinner_data="$(
				printf '%s\n' '#!/bin/bash' "$(declare -f sleep)";

				cat <<'EOF'
set -eu;
while pgrep -f "$HOME/.dotfiles/install.sh" 1>/dev/null; do
	for s in / - \\ \|; do
		sleep 0.1;
		printf '%s \n' "#[bg=#ff5555,fg=#282a36,bold] $s Dotfiles";
	done
done

current_status="$(tmux display -p '#{status-right}')";
tmux set -g status-right "$(printf '%s\n' "$current_status" | sed "s|#(exec $0)||g")"
EOF
		)";
                    local resources_indicator="/usr/bin/tmux-resources-indicator.sh";
                    local resources_indicator_data="$(
				printf '%s\n' '#!/bin/bash' "$(declare -f sleep)";

				cat <<'EOF'
printf '\n'; # init quick draw

while true; do {
	# Read all properties
	IFS=$'\n' read -d '' -r mem_used mem_max cpu_used cpu_max \
		< <(gp top -j | yq -I0 -rM ".resources | [.memory.used, .memory.limit, .cpu.used, .cpu.limit] | .[]")

	# Human friendly memory numbers
	read -r hmem_used hmem_max < <(numfmt -z --to=iec --format="%8.2f" $mem_used $mem_max);

	# CPU percentage
	cpu_perc="$(( (cpu_used * 100) / cpu_max ))";

	# Print to tmux
	printf '%s\n' " #[bg=#ffb86c,fg=#282a36,bold] CPU: ${cpu_perc}% #[bg=#8be9fd,fg=#282a36,bold] MEM: ${hmem_used%?}/${hmem_max} ";
	sleep 3;
} done
EOF
		)";
                    { 
                        printf '%s\n' "$spinner_data" | sudo tee "$spinner";
                        printf '%s\n' "$resources_indicator_data" | sudo tee "$resources_indicator"
                    } > /dev/null;
                    sudo chmod +x "$spinner" "$resources_indicator";
                    tmux set-option -g status-left-length 100\; set-option -g status-right-length 100\; set-option -ga status-right "#(exec $resources_indicator)#(exec $spinner)"
                };
            fi
        } & disown
    };
    function config::shell::bash () 
    { 
        todo
    };
    function config::shell::fish () 
    { 
        if is::cde; then
            { 
                local check_file=(/nix/store/*-fish-*/bin/fish);
                local fish_exec_path;
                if test -n "${check_file:-}"; then
                    { 
                        fish_exec_path="${check_file[0]}";
                        KEEP=true await::create_shim "$fish_exec_path"
                    };
                else
                    { 
                        fish_exec_path="/usr/bin/fish";
                        KEEP="true" SHIM_MIRROR="$HOME/.nix-profile/bin/fish" await::create_shim "$fish_exec_path"
                    };
                fi
            };
        else
            { 
                await::until_true command::exists $HOME/.nix-profile/bin/fish
            };
        fi;
        log::info "Installing fisher and some plugins for fish-shell";
        mkdir -p "$fish_confd_dir";
        { 
            fish -c "curl -sL https://git.io/fisher | source && fisher install ${fish_plugins[*]}"
        } > /dev/null 2>&1;
        CLOSE=true await::create_shim "$fish_exec_path"
    };
    function config::shell::fish::append_hist_from_gitpod_tasks () 
    { 
        await::signal get install_dotfiles;
        log::info "Appending .gitpod.yml:tasks shell histories to fish_history";
        mkdir -p "${fish_hist_file%/*}";
        while read -r _command; do
            { 
                if test -n "$_command"; then
                    { 
                        printf '\055 cmd: %s\n  when: %s\n' "$_command" "$(date +%s)" >> "$fish_hist_file"
                    };
                fi
            };
        done < <(sed "s/\r//g" /workspace/.gitpod/cmd-* 2>/dev/null || :)
    };
    function config::shell::zsh () 
    { 
        todo
    };
    function config::shell () 
    { 
        sed -i '/ set +o history/,/truncate -s 0 "$HISTFILE"/d' "/ide/startup.sh" 2> /dev/null || :;
        case "${DEFAULT_SHELL:-fish}" in 
            "bash")
                config::shell::bash & disown
            ;;
            "fish")
                config::shell::fish & disown;
                config::shell::fish::append_hist_from_gitpod_tasks & disown
            ;;
            "zsh")
                config::shell::zsh & disown
            ;;
        esac;
        config::shell::set_default_vscode_profile & wait
    };
    function config::shell::set_default_vscode_profile () 
    { 
        log::info "Setting the integrated tmux shell for VScode as default";
        local pyh="$HOME/.bashrc.d/60-python";
        if test -e "$pyh"; then
            { 
                sed -i '/local lockfile=.*/,/touch "$lockfile"/c mkdir /tmp/.vcs_add.lock || exit 0' "$pyh"
            };
        fi;
        local json_data;
        json_data="$(
		if [ "${DOTFILES_TMUX:-true}" == true ] && [ "${DOTFILES_TMUX_VSCODE:-true}" == true ]; then {
			cat <<-'JSON' | sed "s|main|${tmux_first_session_name}|g"
			{
				"terminal.integrated.profiles.linux": {
					"tmuxshell": {
						"path": "bash",
						"args": [
							"-c",
							"until cmd=\"$(command -v tmux)\" && test -x \"$cmd\"; do sleep 1; done; AWAIT_SHIM_PRINT_INDICATOR=true tmux new-session -ds main 2>/dev/null || :; if cpids=$(tmux list-clients -t main -F '#{client_pid}'); then for cpid in $cpids; do [ $(ps -o ppid= -p $cpid)x = ${PPID}x ] && exec tmux new-window -n \"vs:${PWD##*/}\" -t main; done; fi; exec tmux attach -t main;"
						]
					}
				},
				"terminal.integrated.defaultProfile.linux": "tmuxshell"
			}
			JSON
		} else {
			shell="$(get::default_shell)" && shell="${shell##*/}";
			cat <<-JSON
			{
				"terminal.integrated.defaultProfile.linux": "$shell"
			}
			JSON
		} fi
	)";
        vscode::add_settings "$vscode_machine_settings_file" "$HOME/.vscode-server/data/Machine/settings.json" "$HOME/.vscode-remote/data/Machine/settings.json" <<< "$json_data"
    };
    function config::scm_cli () 
    { 
        local tarball_url gp_credentials;
        await::until_true command::exists gh;
        await::for_vscode_ide_start;
        local scm_cli_args=("${gitpod_scm_cli}" auth login);
        case "$gitpod_scm_cli" in 
            "gh")
                scm_cli_args+=(--with-token)
            ;;
            "glab")
                scm_cli_args+=(--stdin)
            ;;
        esac;
        local token && if token="$(printf '%s\n' host=github.com | gp credential-helper get | awk -F'password=' '{print $2}')"; then
            { 
                local tries=1;
                until printf '%s\n' "$token" | "${scm_cli_args[@]}"; do
                    { 
                        if test $tries -gt 2; then
                            { 
                                log::error "Failed to authenticate to 'gh' CLI with 'gp' credentials after trying for $tries times with ${token:0:9}" 1 || exit;
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
    function config::editor () 
    { 
        log::info "Setting up editor preset";
        if editor::is "emacs"; then
            { 
                case "${DOTFILES_EDITOR_PRESET:-spacemacs}" in 
                    "spacemacs")
                        editor::emacs::space
                    ;;
                    "doomemacs")
                        editor::emacs::doom
                    ;;
                esac
            };
        else
            if editor::is "neovim"; then
                { 
                    case "${DOTFILES_EDITOR_PRESET:-lunarvim}" in 
                        "lunarvim")
                            editor::neovim::lunar
                        ;;
                        "nvchad")
                            editor::neovim::nvchad
                        ;;
                    esac
                };
            fi;
        fi
    };
    function editor::is () 
    { 
        local target="$1";
        test "${DOTFILES_EDITOR:-neovim}" == "$target"
    };
    function editor::autorun_in_tmux () 
    { 
        ( if test "${DOTFILES_TMUX:-true}" != true; then
            { 
                return
            };
        fi;
        await::signal get config_tmux_session;
        tmux send-keys -t "${tmux_first_session_name}:${tmux_first_window_num}" "$@" Enter ) &
    };
    function editor::emacs::doom () 
    { 
        todo
    };
    function editor::emacs::space () 
    { 
        declare clone_dir="$HOME/.emacs.d";
        await::signal get install_dotfiles;
        if test -e "$clone_dir/.git"; then
            { 
                log::warn "$clone_dir already exists, not making any changes";
                return 0
            };
        fi;
        git clone --depth 1 https://github.com/syl20bnr/spacemacs "$clone_dir" > /dev/null;
        await::until_true test -x "$HOME/.nix-profile/bin/emacs";
        if is::cde; then
            { 
                editor::autorun_in_tmux "emacs"
            };
        fi
    };
    function editor::neovim::lunar () 
    { 
        if test ! -e "$HOME/.config/lvim"; then
            { 
                await::until_true command::exists git;
                await::until_true command::exists nvim;
                curl -sL "https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh" | bash -s -- --no-install-dependencies -y > /dev/null;
                editor::autorun_in_tmux "lvim"
            };
        fi
    };
    function editor::neovim::nvchad () 
    { 
        todo
    };
    export PATH="$PATH:$HOME/.nix-profile/bin";
    declare dotfiles_repos=(https://github.com/axonasif/dotfiles.public);
    : "${DOTFILES_SHELL:=fish}";
    declare -r fish_confd_dir="$HOME/.config/fish/conf.d";
    declare -r fish_hist_file="$HOME/.local/share/fish/fish_history";
    declare fish_plugins+=(PatrickF1/fzf.fish jorgebucaran/fisher);
    : "${DOTFILES_TMUX:=true}";
    : "${DOTFILES_TMUX_VSCODE:=true}";
    declare -r tmux_first_session_name="gitpod";
    declare -r tmux_first_window_num="1";
    : "${DOTFILES_SPAWN_SSH_PROTO:=true}";
    : "${DOTFILES_NO_VSCODE:=false}";
    : "${DOTFILES_EDITOR:=neovim}";
    : "${DOTFILES_EDITOR_PRESET:=lunarvim}";
    declare nixpkgs_level_1+=(nixpkgs.ripgrep nixpkgs.fd nixpkgs.fzf);
    declare nixpkgs_level_2+=(nixpkgs.zoxide nixpkgs.rclone nixpkgs.bat nixpkgs.exa);
    declare nixpkgs_level_3+=(nixpkgs.shellcheck nixpkgs.file nixpkgs.bottom nixpkgs.coreutils nixpkgs.htop nixpkgs.lsof nixpkgs.neofetch nixpkgs.p7zip nixpkgs.rsync);
    if command::exists apt; then
        { 
            aptpkgs_level_1+=(build-essential make gcc)
        };
    else
        { 
            nixpkgs_level_3+=(nixpkgs.gnumake nixpkgs.gcc)
        };
    fi;
    if os::is_darwin; then
        { 
            nixpkgs_level_3+=(nixpkgs.gawk nixpkgs.bashInteractive nixpkgs.reattach-to-user-namespace);
            declare brewpkgs_level_1+=(osxfuse)
        };
    fi;
    declare aptpkgs_level_1+=(fuse);
    declare -r workspace_dir="$(
    if is::gitpod; then {
        printf '%s\n' "/workspace";
    } elif is::codespaces; then {
        printf '%s\n' "/workspaces";
    } fi
)";
    declare -r workspace_persist_dir="$workspace_dir/.persist_root";
    declare -r vscode_machine_settings_file="$(
    if is::gitpod; then {
        : "$workspace_dir";
    } else {
        : "$HOME";
    } fi
    printf '%s\n' "$_/.vscode-remote/data/Machine/settings.json";
)";
    declare -r gitpod_scm_cli="$(
	if [[ "${GITPOD_WORKSPACE_CONTEXT_URL:-}" == *gitlab* ]]     && ! [[ "${GITPOD_WORKSPACE_CONTEXT_URL:-}" == *github.com/* ]]; then {
		: "glab";
    } else {
		: "gh";
    } fi
	printf '%s\n' "$_";
)";
    declare -r dotfiles_sh_repos_dir="$___self_DIR/repos";
    declare -r rclone_mount_dir="$HOME/cloudsync";
    declare -r rclone_conf_file="$HOME/.config/rclone/rclone.conf";
    declare -r rclone_profile_name="cloudsync";
    declare rclone_cmd_args=(--config="$rclone_conf_file" mount --allow-other --async-read --vfs-cache-mode=full "${rclone_profile_name}:" "$rclone_mount_dir");
    declare files_to_persist_locally=("${HISTFILE:-"$HOME/.bash_history"}" "${HISTFILE:-"$HOME/.zsh_history"}" "$fish_hist_file");
    function main () 
    { 
        if test -n "${@:-}"; then
            { 
                filesync::cli "$@"
            };
        fi;
        if ! is::cde; then
            { 
                process::preserve_sudo
            };
        fi;
        if is::codespaces; then
            { 
                local log_file="$HOME/.dotfiles.log";
                log::info "Manually redirecting dotfiles install.sh logs to $log_file";
                exec >> "$log_file";
                exec 2>&1
            };
        fi;
        install::packages;
        install::misc & disown;
        install::dotfiles & disown;
        install::filesync & disown;
        config::tmux & if is::cde; then
            { 
                config::shell &
            };
        fi;
        if is::gitpod; then
            { 
                config::scm_cli & disown
            };
        fi;
        config::editor & disown;
        log::info "Waiting for background jobs to complete" && jobs -l;
        while test -n "$(jobs -rp)" && sleep 0.2; do
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
main@bashbox%22078 "$@";
