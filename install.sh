#!/usr/bin/env bash
main@bashbox%5539 () 
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
    ___MAIN_FUNCNAME='main@bashbox%5539';
    ___self_NAME="dotfiles";
    ___self_CODENAME="dotfiles";
    ___self_AUTHORS=("AXON <axonasif@gmail.com>");
    ___self_VERSION="1.0";
    ___self_DEPENDENCIES=(std::193c820);
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
    function live () 
    { 
        ( local container_image="axonasif/dotfiles-testing:latest";
        source "$_arg_path/src/utils/common.sh";
        cmd="bashbox build --release";
        log::info "Running $cmd";
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
            docker_args+=(run --rm --net=host);
            docker_args+=(-v "$duplicate_workspace_root:/workspace" -v "$duplicate_repo_root:$HOME/.dotfiles");
            if is::gitpod; then
                { 
                    docker_args+=(-v /usr/bin/gp:/usr/bin/gp:ro)
                };
            fi;
            local dotfiles_sh_dir="$HOME/.dotfiles-sh";
            if test -e "$dotfiles_sh_dir"; then
                { 
                    docker_args+=(-v "$dotfiles_sh_dir:$dotfiles_sh_dir")
                };
            fi;
            if is::gitpod; then
                { 
                    docker_args+=(-e GP_EXTERNAL_BROWSER -e GP_OPEN_EDITOR -e GP_PREVIEW_BROWSER -e GITPOD_ANALYTICS_SEGMENT_KEY -e GITPOD_ANALYTICS_WRITER -e GITPOD_CLI_APITOKEN -e GITPOD_GIT_USER_EMAIL -e GITPOD_GIT_USER_NAME -e GITPOD_HOST -e GITPOD_IDE_ALIAS -e GITPOD_INSTANCE_ID -e GITPOD_INTERVAL -e GITPOD_MEMORY -e GITPOD_OWNER_ID -e GITPOD_PREVENT_METADATA_ACCESS -e GITPOD_REPO_ROOT -e GITPOD_REPO_ROOTS -e GITPOD_THEIA_PORT -e GITPOD_WORKSPACE_CLASS -e GITPOD_WORKSPACE_CLUSTER_HOST -e GITPOD_WORKSPACE_CONTEXT -e GITPOD_WORKSPACE_CONTEXT_URL -e GITPOD_WORKSPACE_ID -e GITPOD_WORKSPACE_URL -e GITPOD_TASKS='[{"name":"Test foo","command":"echo This is fooooo"},{"name":"Test boo", "command":"echo This is boooo"}]' -e DOTFILES_SPAWN_SSH_PROTO=false)
                };
            fi;
            docker_args+=(-it "$container_image");
            function startup_command () 
            { 
                local logfile="$HOME/.dotfiles.log";
                local tail_cmd="less -XR +F $logfile";
                eval "$(gp env -e)";
                set +m;
                { 
                    "$HOME/.dotfiles/install.sh" 2>&1
                } > "$logfile" 2>&1 & disown;
                ( until tmux has-session 2> /dev/null; do
                    sleep 1;
                done;
                pkill -9 -f "${tail_cmd//+/\\+}" || :;
                tmux setw -g mouse on;
                tmux send-keys "$tail_cmd" Enter;
                until test -n "$(tmux list-clients)"; do
                    sleep 1;
                done;
                printf '====== %% %s\n' "Run 'tmux detach' to exit from here" "Press 'ctrl+c' and then 'q' to interrupt the data-pager" "You can click between tabs/windows in the bottom" >> "$logfile" ) & disown;
                set -m;
                $tail_cmd;
                printf '%s\n' "PS1='testing-dots \w \$ '" >> "$HOME/.bashrc";
                export PATH="$HOME/.nix-profile/bin:$PATH";
                ___self_AWAIT_SHIM_PRINT_INDICATOR=true tmux new-window -n ".dotfiles.log" "$tail_cmd" \; attach;
                printf 'INFO: \n\n%s\n\n' "Switching to a fallback debug bash shell";
                exec bash -l
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
            local confirmed_statfile="/tmp/.confirmed_statfile";
            touch "$confirmed_statfile";
            local confirmed_times="$(( $(<"$confirmed_statfile") + 1 ))";
            if [[ "$confirmed_times" -lt 3 ]]; then
                { 
                    printf '\n';
                    printf 'INFO: %b\n' "Now this will boot into a simulated Gitpod workspace" "To exit from there, you can press ${BGREEN}Ctrl+d${RC} or run ${BRED}exit${RC} on the terminal when in ${GRAY}bash${RC} shell" "You can run ${ORANGE}tmux${RC} a on the terminal to attach to the tmux session where Gitpod tasks are opened as tmux-windows" "To exit detach from the tmux session, you can run ${BPURPLE}tmux detach${RC}";
                    printf '\n';
                    read -r -p '>>> Press Enter/return to continue execution of "bashbox live" command';
                    printf '%s\n' "$confirmed_times" > "$confirmed_statfile"
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
            docker "${docker_args[@]}" -c "$(printf "%s\n" "$(declare -f startup_command)" "startup_command")"
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
                log::info "Awaiting for another ${name} job to finish"
            };
        fi;
        while { 
            kill -0 "$(< "$lock_file")"
        } 2> /dev/null; do
            { 
                sleep 0.5
            };
        done;
        until ( set -o noclobber;
        printf '%s\n' "$$" > "$lock_file" ) 2> /dev/null; do
            { 
                sleep 0.5
            };
        done;
        trap::append "rm -f '$lock_file' 2>/dev/null" ${SIGNALS:-EXIT}
    };
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
    function vscode::add_settings () 
    { 
        SIGNALS="RETURN ERR EXIT" lockfile "vscode_addsettings";
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
                if test ! -s "$settings_file" || ! jq -reM '""' "$settings_file" > /dev/null; then
                    { 
                        printf '%s\n' "$input" > "$settings_file"
                    };
                else
                    { 
                        sed -i -e 's|,}|\n}|g' -e 's|, }|\n}|g' -e ':begin;$!N;s/,\n}/\n}/g;tbegin;P;D' "$settings_file";
                        cp -a "$settings_file" "$tmp_file";
                        jq -s '.[0] * .[1]' - "$tmp_file" <<< "$input" > "$settings_file";
                        rm -f "$tmp_file"
                    };
                fi
            };
        done
    };
    function dotfiles::initialize () 
    { 
        local installation_target="${INSTALL_TARGET:-"$HOME"}";
        local last_applied_filelist="$installation_target/.last_applied_dotfiles";
        local dotfiles_repo local_dotfiles_repo_count;
        local repo_user repo_name source_dir repo_dir_name check_dir;
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
                "$@" 2> /dev/null || sudo "$@"
            }
        };
        function is::custom_shim () 
        { 
            test -v CUSTOM_SHIM_SOURCE
        };
        function revert_shim () 
        { 
            try_sudo touch "$shim_tombstone";
            if ! is::custom_shim; then
                { 
                    if test -e "$shim_source"; then
                        { 
                            try_sudo mv "$shim_source" "$target"
                        };
                    fi
                };
            else
                { 
                    try_sudo mv "$shim_source" "$CUSTOM_SHIM_SOURCE";
                    try_sudo rm "$target"
                };
            fi;
            ( sleep 5 && try_sudo rm -f "$shim_tombstone";
            try_sudo rmdir --ignore-fail-on-non-empty "$shim_dir" 2> /dev/null || : ) & disown;
            unset KEEP_internal_call CUSTOM_SHIM_SOURCE
        };
        function create_self () 
        { 
            function cmd () 
            { 
                printf '%s\n' '#!/usr/bin/env bash' "$(declare -f main)" 'main "$@"'
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
        local target shim_source;
        if test -v CUSTOM_SHIM_SOURCE; then
            export CUSTOM_SHIM_SOURCE="${CUSTOM_SHIM_SOURCE:-}";
        fi;
        local shim_dir shim_source shim_tombstone;
        for target in "$@";
        do
            { 
                if ! is::custom_shim; then
                    { 
                        shim_dir="${target%/*}/.ashim";
                        shim_source="${shim_dir}/${target##*/}"
                    };
                else
                    { 
                        shim_dir="${CUSTOM_SHIM_SOURCE%/*}/.cshim";
                        shim_source="$shim_dir/${CUSTOM_SHIM_SOURCE##*/}"
                    };
                fi;
                shim_tombstone="${shim_source}.tombstone";
                if test -v CLOSE; then
                    { 
                        revert_shim;
                        return
                    };
                fi;
                if test -e "$target"; then
                    { 
                        log::warn "${FUNCNAME[0]}: $target already exists";
                        if ! is::custom_shim; then
                            { 
                                try_sudo mv "$target" "$shim_source"
                            };
                        fi
                    };
                fi;
                local USER && USER="$(id -u -n)";
                try_sudo sh -c "touch \"$target\" && chown $USER:$USER \"$target\"";
                function async_wrapper () 
                { 
                    set -eu;
                    diff_target="/tmp/.diff_${RANDOM}.${RANDOM}";
                    if test ! -e "$diff_target"; then
                        { 
                            create_self "$diff_target"
                        };
                    fi;
                    function await_for_no_open_writes () 
                    { 
                        while lsof -F 'f' -- "$1" 2> /dev/null | grep -q '^f.*w$'; do
                            sleep 0.5${RANDOM};
                        done
                    };
                    function exec_bin () 
                    { 
                        local args=("$@");
                        local bin="${args[0]}";
                        await::until_true test -x "$bin";
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
                                TIME="0.5${RANDOM}" await::while_true test -e "$checkf"
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
                                TIME="0.5${RANDOM}" await::while_true cmp --silent -- "$target" "$diff_target";
                                rm -f "$diff_target" 2> /dev/null || :;
                                TIME="0.5${RANDOM}" await_for_no_open_writes "$target"
                            };
                        else
                            { 
                                TIME="0.5${RANDOM}" await::for_file_existence "$CUSTOM_SHIM_SOURCE";
                                await_for_no_open_writes "$CUSTOM_SHIM_SOURCE"
                            };
                        fi;
                    fi;
                    if test -v KEEP_internal_call; then
                        { 
                            if test "${KEEP_internal_call:-}" == true; then
                                { 
                                    if test ! -e "$shim_tombstone" && test ! -e "$shim_source"; then
                                        { 
                                            try_sudo mkdir -p "${shim_source%/*}";
                                            if ! is::custom_shim; then
                                                { 
                                                    try_sudo mv "$target" "$shim_source";
                                                    try_sudo env self="$(NO_PRINT=true create_self)" target="$target" sh -c 'printf "%s\n" "$self" > "$target" && chmod +x $target'
                                                };
                                            else
                                                { 
                                                    try_sudo mv "${CUSTOM_SHIM_SOURCE}" "$shim_source"
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
                    if is::custom_shim; then
                        { 
                            target="$CUSTOM_SHIM_SOURCE"
                        };
                    fi;
                    exec_bin "$target" "$@"
                };
                { 
                    printf 'function main() {\n';
                    printf '%s="%s"\n' target "$target" shim_source "$shim_source" shim_dir "$shim_dir";
                    if test -v CUSTOM_SHIM_SOURCE; then
                        { 
                            printf '%s="%s"\n' CUSTOM_SHIM_SOURCE "$CUSTOM_SHIM_SOURCE"
                        };
                    fi;
                    if test -v KEEP; then
                        { 
                            printf '%s="%s"\n' "KEEP_internal_call" '${KEEP_internal_call:-false}' shim_tombstone "$shim_tombstone";
                            export KEEP_internal_call=true
                        };
                    fi;
                    printf '%s\n' "$(declare -f await::while_true await::until_true await::for_file_existence sleep is::custom_shim try_sudo create_self async_wrapper)";
                    printf '%s\n' 'async_wrapper "$@"; }'
                } > "$target";
                ( source "$target";
                create_self "$target" );
                chmod +x "$target"
            };
        done
    };
    syspkgs_level_one=(tmux fish jq);
    syspkgs_level_two=();
    userpkgs_level_one=(tmux fish jq);
    if std::sys::info::distro::is_ubuntu && is::cde; then
        { 
            userpkgs_level_one=()
        };
    fi;
    userpkgs_level_two=(lsof shellcheck tree file fzf bat bottom exa fzf gh neofetch neovim p7zip ripgrep shellcheck tree jq zoxide);
    function install::packages () 
    { 
        log::info "Installing system packages";
        ( sudo apt-get update;
        sudo debconf-set-selections <<< 'debconf debconf/frontend select Noninteractive';
        for level in syspkgs_level_one syspkgs_level_two;
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
        sudo debconf-set-selections <<< 'debconf debconf/frontend select Readline' ) > /dev/null & disown;
        log::info "Installing userland packages";
        ( USER="$(id -u -n)" && export USER;
        if test ! -e /nix; then
            { 
                sudo sh -c "mkdir -p /nix && chown -R $USER:$USER /nix";
                log::info "Installing nix";
                curl -sL https://nixos.org/nix/install | bash -s -- --no-daemon > /dev/null 2>&1
            };
        fi;
        source "$HOME/.nix-profile/etc/profile.d/nix.sh" || source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh;
        for level in userpkgs_level_one userpkgs_level_two;
        do
            { 
                declare -n ref="$level";
                if test -n "${ref:-}"; then
                    { 
                        nix-env -f channel:nixpkgs-unstable -iA "${ref[@]}" > /dev/null 2>&1
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
        printf 'source %s\n' "$HOME/.bashbox/env" > "$HOME/$_/bashbox.bash" ) & disown
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
    function install::dotfiles () 
    { 
        log::info "Installing dotfiles";
        local dotfiles_repos=("${DOTFILES_PRIMARY_REPO:-https://github.com/axonasif/dotfiles.public}");
        dotfiles::initialize "${dotfiles_repos[@]}";
        await::signal send install_dotfiles
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
        tmux new-session -c "${GITPOD_REPO_ROOT:-$HOME}" -n editor -ds "${tmux_first_session_name}" 2> /dev/null || :;
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
        local pyh="$HOME/.bashrc.d/60-python";
        if test -e "$pyh"; then
            { 
                sed '/local lockfile=.*/,/touch "$lockfile"/c mkdir /tmp/.vcs_add.lock || exit 0' "$pyh"
            };
        fi;
        local json_data;
        json_data="$(cat <<-'JSON' | sed "s|main|${tmux_first_session_name}|g"
		{
			"terminal.integrated.profiles.linux": {
				"tmuxshell": {
					"path": "bash",
					"args": [
						"-c",
						"set -x && exec 2>>/tmp/.tvlog; until command -v tmux 1>/dev/null; do sleep 1; done; tmux new-session -ds main 2>/dev/null || :; if cpids=$(tmux list-clients -t main -F '#{client_pid}'); then for cpid in $cpids; do [ $(ps -o ppid= -p $cpid)x == ${PPID}x ] && exec tmux new-window -n \"vs:${PWD##*/}\" -t main; done; fi; exec tmux attach -t main; "
					]
				}
			},
			"terminal.integrated.defaultProfile.linux": "tmuxshell"
		}
	JSON
	)";
        vscode::add_settings "$vscode_machine_settings_file" "$HOME/.vscode-server/data/Machine/settings.json" "$HOME/.vscode-remote/data/Machine/settings.json" <<< "$json_data"
    };
    function config::tmux () 
    { 
        local tmux_exec_path="/usr/bin/tmux";
        log::info "Setting up tmux";
        if is::cde; then
            { 
                KEEP="true" await::create_shim "$tmux_exec_path"
            };
        else
            { 
                await::until_true command -v tmux > /dev/null
            };
        fi;
        if is::cde; then
            { 
                config::tmux::set_tmux_as_default_vscode_shell & disown
            };
        fi;
        { 
            if is::gitpod; then
                { 
                    if test "${DOTFILES_SPAWN_SSH_PROTO:-true}" == true; then
                        { 
                            tmux::start_vimpod & disown
                        };
                    fi;
                    config::tmux::hijack_gitpod_task_terminals &
                };
            fi;
            local target="$HOME/.tmux/plugins/tpm";
            if test ! -e "$target"; then
                { 
                    git clone --filter=tree:0 https://github.com/tmux-plugins/tpm "$target" > /dev/null 2>&1;
                    await::signal get install_dotfiles;
                    bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" || :
                };
            fi;
            CLOSE=true await::create_shim "$tmux_exec_path";
            if is::cde; then
                { 
                    local tmux_default_shell;
                    tmux::create_session
                };
            fi;
            ( if is::gitpod; then
                { 
                    if test -n "${GITPOD_TASKS:-}"; then
                        { 
                            log::info "Spawning Gitpod tasks in tmux"
                        };
                    else
                        { 
                            exit
                        };
                    fi;
                    await::for_file_existence "$workspace_dir/.gitpod/ready";
                    if ! cd "${GITPOD_REPO_ROOT:-}"; then
                        { 
                            log::error "Can't cd into ${GITPOD_REPO_ROOT:-}" 1 || exit
                        };
                    fi;
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
                    local name cmd arr_elem=0;
                    until { 
                        ! cmd_prebuild="$(jqw ".[${arr_elem}] | [.init] | map(select(. != null)) | .[]")" && ! cmd_others="$(jqw ".[${arr_elem}] | [.before, .command] | map(select(. != null)) | .[]")"
                    }; do
                        { 
                            if ! name="$(jqw ".[${arr_elem}].name")"; then
                                { 
                                    name="AnonTask-${arr_elem}"
                                };
                            fi;
                            local prebuild_log="$workspace_dir/.gitpod/prebuild-log-${arr_elem}";
                            cmd="$(
						task="$(
							if test -e "$prebuild_log"; then {
								printf 'cat %s\n' "$prebuild_log";
								printf '%s\n' "${cmd_others:-}";
							} else {
								printf '%s\n' "${cmd_prebuild:-}" "${cmd_others:-}";
							} fi
						)"
IFS='' read -rd '' cmdc <<CMDC || :;
trap "exec /usr/bin/fish -l" EXIT
printf "$BGREEN>> Executing task:$RC\n";
IFS='' read -rd '' lines <<'EOF' || :;
$task
EOF
printf '%s\n' "\$lines" | while IFS='' read -r line; do
	printf "    ${YELLOW}%s${RC}\n" "\$line";
done
printf '\n';
$task
CMDC
						printf '%s\n' "$cmdc";
					)";
                            WINDOW_NAME="$name" tmux::create_window bash -cli "$cmd";
                            ((arr_elem=arr_elem+1))
                        };
                    done;
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
		< <(gp top -j | jq -r ".resources | [.memory.used, .memory.limit, .cpu.used, .cpu.limit] | .[]")

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
            else
                if is::codespaces && test -e "${CODESPACES_VSCODE_FOLDER:-}"; then
                    { 
                        cd "$CODESPACE_VSCODE_FOLDER" || :
                    };
                fi;
            fi ) || :;
            await::signal send config_tmux
        } & disown
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
        await::signal get install_dotfiles;
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
    function config::gh () 
    { 
        local tarball_url gp_credentials;
        await::until_true command -v gh > /dev/null;
        await::for_vscode_ide_start;
        if [[ "$(printf '%s\n' host=github.com | gp credential-helper get)" =~ password=(.*) ]]; then
            { 
                local token="${BASH_REMATCH[1]}";
                local tries=1;
                until printf '%s\n' "$token" | gh auth login --with-token > /dev/null 2>&1; do
                    { 
                        if test $tries -gt 5; then
                            { 
                                log::error "Failed to authenticate to 'gh' CLI with 'gp' credentials after trying for $tries times" 1 || exit;
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
    function config::neovim () 
    { 
        log::info "Setting up Neovim";
        if is::cde; then
            { 
                CUSTOM_SHIM_SOURCE="$HOME/.nix-profile/bin/nvim" await::create_shim "/usr/bin/nvim"
            };
        else
            { 
                await::until_true command -v nvim > /dev/null
            };
        fi;
        if test ! -e "$HOME/.config/lvim"; then
            { 
                curl -sL "https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh" | bash -s -- --no-install-dependencies -y
            };
        fi;
        if is::cde; then
            { 
                await::signal get config_tmux;
                tmux send-keys -t "${tmux_first_session_name}:${tmux_first_window_num}" "lvim" Enter
            };
        fi
    };
    export PATH="$PATH:$HOME/.nix-profile/bin";
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
    declare -r dotfiles_sh_home="$HOME/.dotfiles-sh";
    declare -r dotfiles_sh_repos_dir="$dotfiles_sh_home/repos";
    function main () 
    { 
        if is::codespaces; then
            { 
                local log_file="$HOME/.dotfiles.log";
                log::info "Manually redirecting dotfiles install.sh logs to $log_file";
                exec >> "$log_file";
                exec 2>&1
            };
        fi;
        install::dotfiles & disown;
        config::tmux & config::fish & disown;
        install::packages & disown;
        install::misc & disown;
        if is::cde; then
            { 
                config::shell::persist_history & disown
            };
        fi;
        if is::gitpod; then
            { 
                config::docker_auth & disown;
                config::gh & disown;
                config::shell::fish::append_hist_from_gitpod_tasks & disown
            };
        fi;
        config::neovim & disown;
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
main@bashbox%5539 "$@";
