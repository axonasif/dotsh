use tmux;
use shell;
use scm_cli;
use editor;

function config::cli() {
  
  declare dotfiles_sh_dir="$(get::dotfiles-sh_dir)";
  declare variables_file="$dotfiles_sh_dir/src/variables.sh";
  declare -a possible_options=(
    DOTFILES_SHELL
    DOTFILES_TMUX  
    DOTFILES_TMUX_VSCODE
    DOTFILES_SPAWN_SSH_PROTO
    DOTFILES_NO_VSCODE
    DOTFILES_EDITOR
    DOTFILES_EDITOR_PRESET
  )

  function update_option(){ 

    declare key="$1";
    declare value="$2";

    if grep -q "${key}:=" "$variables_file"; then
      # TODO: Improve this
      sed -i "s|${key}:=.*}|${key}:=${value}}|" "$variables_file";
    else
      printf ': "${%s:=%s}";\n' "$key" "$value" >> "$variables_file";
    fi

  }

  function fetch_option_value(){ 
    declare key="$1";
    declare value;

    if {
      value="$(grep -m1 "${key}:=" "$variables_file")" \
        && eval "$value" && declare -n value=$key \
        && test -n "${value:-}"
    }; then {
      : "$value";
    } elif test -n "${DEFAULT:-}"; then {
      : "${DEFAULT}";
    } else {
      return 1;
    } fi
    
    printf '%s\n' "$_";
  }

  function cli::set() {

    case "${1:-}" in
      -h|--help)
        printf '%s\t%s\n' \
          "-h|--help" "This help message" \
          "-q|--quiet" "Do not print anything";
        exit;
        ;;
      -q|--quiet)
        declare arg_quiet=true;
        ;;
    esac
  }

  function cli::wizard() {
    PS3="$(echo -e "\n${RED}#${RC} Enter your choice number > ")";

    create_prompt() {
      {
        printf '\n';

        if test -n "${QUESTION:-}"; then {
          printf "${BGREEN}Question${RC}: %s\n" "$QUESTION";
        } fi

        printf "${YELLOW}Option name${RC}: %s\n" "$OPT_NAME";

        declare cur_value;
        if cur_value="$(DEFAULT="$OPT_DEFAULT_VALUE" fetch_option_value "$OPT_NAME")"; then {
          printf "${BBLUE}Current value${RC}: %s\n" "$cur_value";
        } fi

        printf '\n';
      } >&2

      # Human friendly options for preview
      human_machine_friendly() {
        declare input="$1";

        case "${1:-}" in 
          "true")
            : "yes";
            ;;
          "false")
            : "no";
            ;;
          "yes")
            : "true";
            ;;
          "no")
            : "false";
            ;;
          *)
            : "$input";
            ;;
        esac

        printf '%s\n' "$_";
      }

      declare -a options;
      declare opt;

      for opt in "$@"; do {
        options+=("$(human_machine_friendly "$opt")");
      } done

      select opt in "${options[@]}"; do
        if test -n "${opt:-}"; then {
          update_option "$OPT_NAME" "$(human_machine_friendly "$opt")";
          break;
        } fi
      done
    } 

    declare user_choice;

    printf '## %s\n' \
      "This will walk you through for configuring some core options." \
      "You may directly modify $(echo -e "${BGREEN}$variables_file${RC}") for greater customization later on." \
      "You can also non-interactively set some of the option values like so: $(echo -e "${BBLUE}dotsh config set <option> <value>${RC}")";
    printf '\n';

    OPT_NAME='DOTFILES_SHELL' \
    OPT_DEFAULT_VALUE="fish" \
    QUESTION="Which SHELL do you want to use?" \
      create_prompt bash fish zsh;

    OPT_NAME='DOTFILES_TMUX' \
    OPT_DEFAULT_VALUE="true" \
    QUESTION="Do you want the Tmux integration?" \
      create_prompt true false;

    OPT_NAME='DOTFILES_TMUX_VSCODE' \
    OPT_DEFAULT_VALUE="true" \
    QUESTION="Should VSCode also use Tmux integration?" \
      create_prompt true false;

    OPT_NAME='DOTFILES_SPAWN_SSH_PROTO' \
    OPT_DEFAULT_VALUE="true" \
    QUESTION="Do you want auto ssh:// launch for quick SSHing via your terminal emulator?" \
      create_prompt true false;

    OPT_NAME='DOTFILES_NO_VSCODE' \
    OPT_DEFAULT_VALUE="false" \
    QUESTION="Do you want to automatically kill VSCode process to only use SSH? (i.e. less CPU/RAM consumption)" \
      create_prompt true false;

    OPT_NAME='DOTFILES_EDITOR' \
    OPT_DEFAULT_VALUE="neovim" \
    QUESTION="Which is your preferred CLI EDITOR?" \
      create_prompt emacs helix neovim;

    if is::gitpod && ! test -e "$HOME/.dotfiles/src/variables.sh"; then {
      read -n 1 -r -p "$(echo -e ">> Do you want to fork this repo and setup it for Gitpod? [Y/n]")";
      declare target_repo_url="$___self_REPOSITORY";

      if [ "${REPLY,,}" = y ]; then {

        # Install gh CLI if missing
        if ! command::exists gh; then {
          log::info "Installing gh CLI";
          PIPE="| tar --strip-components=1 -C /usr -xpz" \
            dw "/usr/bin/gh" "https://github.com/cli/cli/releases/download/v2.20.0/gh_2.20.0_linux_amd64.tar.gz"; 
        } fi

        # Login into GitHub if needed
        if ! gh auth status >/dev/null 2>&1; then {
          log::info "Trying to login into gh CLI";
          declare token;
          token="$(printf '%s\n' host=github.com | gp credential-helper get | awk -F'password=' '{print $2}')" || {
            log::error "Failed to retrieve Github auth token from 'gp credential-helper'" || exit;
          };
          until printf '%s\n' "$token" | gh auth login --with-token || {
            log::warn "Failed to login to Github via gh CLI.
Please make sure you have the necessary ^ scopes enabled at ${ORANGE}https://gitpod.io/integrations > GitHub > Edit permissions${RC}";
            read -n 1 -r -p "$(echo -e "Press ${GREEN}Enter${RC} to try again after you've fixed the permissions...")";
            false;
          }; do continue; done
        } fi

        # Create fork
        gh repo fork "$___self_REPOSITORY";
        target_repo_url="$(
          gh api graphql -F name="${___self_REPOSITORY##*/}" -f query='
            query ($name: String!) {
              viewer {
                repository(name: $name) {
                  url
                }
              }
            }' --jq '.data.viewer.repository.url'
        )";

        # Update git remotes
        log::info "Updating git remotes for $dotfiles_sh_dir";
        (
          cd "$dotfiles_sh_dir";

          git remote set-url origin "$target_repo_url";

          if ! git config --local remote.upstream.url 1>/dev/null; then {
            : "add";
          } else {
            : "set-url";
          } fi
          git remote "$_" upstream "$___self_REPOSITORY";
        )
      } else {
        log::info "That's fine too! But feel free to fork later if you want to persist your customizations!";
      } fi

      log::info "Go to ${ORANGE}https://gitpod.io/preferences${RC} and set ${BGREEN}${target_repo_url}${RC} in the bottom dotfiles-url field";

    } fi
  }

    case "${1:-}" in
      "config")
        shift;
      ;;
      *) 
        return;
      ;;
    esac

    case "${1:-}" in
      -h|--help)
        printf '%s\t%s\n' \
          "set" "Set and update option values on the fly" \
          "wizard" "Quick interactive onboarding" \
          "rclone" "Configure rclone for filesync" \
          "-h|--help" "This help message";
        ;;
      set)
        shift;
        cli::set "$@";
        ;;
      * | wizard)
        shift || true;
        cli::wizard "$@";
        ;;
      rclone)
        cli::rclone "$@";
        ;;
    esac

    exit;
}
