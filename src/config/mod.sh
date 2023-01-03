use tmux;
use shell;
use scm_cli;
use editor;
# use example;

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
      unset "$key"; # For resetting self-variables
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

    create_prompt() {
      {
        printf '\n';

        if test -n "${QUESTION:-}"; then {
          printf "${BGREEN}Question${RC}: %s\n" "$QUESTION";
        } fi

        printf "${YELLOW}Option name${RC}: %s\n" "$OPT_NAME";

        declare cur_value;
        if cur_value="$(DEFAULT="$OPT_DEFAULT_VALUE" fetch_option_value "$OPT_NAME")"; then {
          printf "${BBLUE}Current value${RC}: %s\n" "$(human_machine_friendly $cur_value)";
        } fi

        printf '\n';
      }


      declare -a options;
      declare opt;

      for opt in "$@"; do {
        options+=("$(human_machine_friendly "$opt")");
      } done

      select opt in "${options[@]}"; do
        if test -z "${opt:-}"; then {
          log::warn "Reusing the current value: $(human_machine_friendly $cur_value)";
          opt="$cur_value";
        } fi
        update_option "$OPT_NAME" "$(human_machine_friendly "$opt")";
        break;
      done
    } 

    declare user_choice;

    printf '## %s\n' \
      "This will walk you through for configuring some core options." \
      "You may directly modify $(echo -e "${BGREEN}$variables_file${RC}") for greater customization later on." \
      "You can also non-interactively set some of the option values like so: $(echo -e "${BBLUE}${___self} config set <option> <value>${RC}")";
    printf '\n';

    OPT_NAME='DOTFILES_SHELL' \
    OPT_DEFAULT_VALUE="fish" \
    QUESTION="Which SHELL do you want to use?" \
      create_prompt bash fish zsh;

    OPT_NAME='DOTFILES_TMUX' \
    OPT_DEFAULT_VALUE="true" \
    QUESTION="Do you want the Tmux integration?" \
      create_prompt true false;

    if test "$(DEFAULT=true fetch_option_value DOTFILES_TMUX)" = true; then {
      OPT_NAME='DOTFILES_TMUX_VSCODE' \
      OPT_DEFAULT_VALUE="true" \
      QUESTION="Should VSCode also use Tmux integration?" \
        create_prompt true false;
    } fi

    OPT_NAME='DOTFILES_SPAWN_SSH_PROTO' \
    OPT_DEFAULT_VALUE="true" \
    QUESTION="Do you want auto ssh:// launch for quick SSHing via your terminal emulator?" \
      create_prompt true false;


    if test "$(DEFAULT=true fetch_option_value DOTFILES_SPAWN_SSH_PROTO)" = true; then {
      OPT_NAME='DOTFILES_NO_VSCODE' \
      OPT_DEFAULT_VALUE="false" \
      QUESTION="Do you want to automatically kill VSCode process to only use SSH?" \
        create_prompt true false;
    } fi

    OPT_NAME='DOTFILES_EDITOR' \
    OPT_DEFAULT_VALUE="neovim" \
    QUESTION="Which CLI EDITOR do you use?" \
      create_prompt emacs helix neovim;

    # Dotfiles repo question
    read -n 1 -r -p "$(echo -e ">> Do you have your own dotfiles repo? [Y/n] ")";
    printf '\n';
    declare template_dotfiles_repo="https://github.com/axonasif/dotfiles";

    if [ "${REPLY,,}" = y ]; then {
      read -r -p "$(echo -e ">> Enter your dotfiles repo URL: ")";
      printf '\n';
      sed -i "s|$template_dotfiles_repo|${REPLY}|g" "$variables_file";
      log::info "Updated $variables_file with your dotfiles repo URL";
    } else {
      log::info "No worries, ${template_dotfiles_repo} will be used, customize it later if you want from ${BGREEN}${variables_file}${RC} file";
    } fi

    # Change CWD
    cd "$dotfiles_sh_dir";

    if is::gitpod && ! test -e "$HOME/.dotfiles/src/variables.sh"; then {

      read -n 1 -r -p "$(echo -e ">> Do you want to fork (GitHub only) this repo and setup it for Gitpod? [Y/n] ")";
      printf '\n';
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

          until printf '%s\n' "host=github.com" \
                | gp credential-helper get \
                | awk -F'password=' '{print $2}' \
                | gh auth login --with-token; do 
            echo -e "Failed to login to GitHub via gh CLI.\nPlease make sure you have the necessary ^ scopes enabled at ${ORANGE}https://gitpod.io/integrations > GitHub > Edit permissions${RC}";
            read -n 1 -r -p "$(echo -e "Press ${GREEN}Enter${RC} to try again after you've fixed the permissions...")";
          done
        } fi

        get_target_repo_url() {
          declare source_repo_name="${___self_REPOSITORY##*/}";
          source_repo_name="${source_repo_name%.git}";

          target_repo_url="$(
            gh api graphql -F name="$source_repo_name" -f query='
              query ($name: String!) {
                viewer {
                  repository(name: $name) {
                    url
                  }
                }
              }' --jq '.data.viewer.repository.url'
          )";
        }

        # Create fork
        if ! get_target_repo_url >/dev/null 2>&1; then {
          gh repo fork "$___self_REPOSITORY" --clone=false;
          get_target_repo_url;
        } fi

        # Update git remotes
        log::info "Updating git remotes for $dotfiles_sh_dir";

        git remote set-url origin "$target_repo_url";

        if ! git config --local remote.upstream.url 1>/dev/null; then {
          : "add";
        } else {
          : "set-url";
        } fi
        git remote "$_" upstream "$___self_REPOSITORY";

      } else {
        log::info "That's fine too! But feel free to fork later if you want to persist your customizations!";
      } fi

      log::info "Go to ${ORANGE}https://gitpod.io/preferences${RC} and set ${BGREEN}${target_repo_url}${RC} in the bottom URL field if you haven't yet";

    } fi


    read -n 1 -r -p "$(echo -e ">> Do you want to commit and push the changes? [Y/n] ")";
    printf '\n';
    if [ "${REPLY,,}" = y ]; then {
      # Push the changes there
      _arg_path="$dotfiles_sh_dir" bashbox::build::before
      declare cmd="bashbox build --release";
      log::info "Running: ${BGREEN}$cmd${RC}";

      log::info "Committing the changes on $dotfiles_sh_dir";
      git commit -am 'Update dotsh config' 1>/dev/null;

      log::info "Pushing the changes to $target_repo_url";
      git pull --ff --no-edit 1>/dev/null;
      git push origin main;
    } fi

  }

  function cli::rclone() {
    if test ! -e "$HOME/.dotfiles/src/variables.sh"; then {
      log::error "You need to start a workspace with dotsh loaded to configure this" 1 || exit;
    } fi

    declare rclone_conf_dir="${rclone_conf_file%/*}";
    if test -e "$rclone_conf_dir"; then {
      log::warn "Maybe you already configured rclone once";
      sudo chmod -R 755 "$rclone_conf_dir";
    } fi

    log::warn "${YELLOW}Make sure to open your workspace in VSCode-Desktop or Jetbrains as browser Auth will not work on the web version${RC}";

    declare cmd="rclone config";
    log::info "Executing $cmd";
    log::info "${BGREEN}Create a${RC} ${RED}New remote${RC} ${BGREEN}on rclone${RC}";
    $cmd || {
      log::error "$cmd did not exit gracefully" || exit;
    };

    if test ! -e "$rclone_conf_file"; then {
      log::error "No profile was setup, please try again" 1 || exit;
    } fi

    log::info "Renaming your 1st rclone profile to $rclone_profile_name";
    sed -i "1s|\[.*\]|\[${rclone_profile_name}\]|" "$rclone_conf_file";

    log::info "Base64 encoding ${rclone_conf_file##*/} and saving at https://gitpod.io/variables";
    declare -n rclone_data="$rclone_gitpod_env_var_name";
    rclone_data="$(base64 -w0 "$rclone_conf_file")";
    export rclone_data; # For filesync::mount_rclone
    gp env "${rclone_gitpod_env_var_name}"="$rclone_data" 1>/dev/null;

    log::info ">> ${BGREEN} Go to${RC} ${ORANGE}https://gitpod.io/variables${RC} ${BGREEN}and set the scope of ${rclone_gitpod_env_var_name} to${RC} ${BRED}*/*${RC}";
    log::info ">> Press ${BGREEN}Enter${RC} after you've done that ... " && read || true;

    if ! mountpoint -q "$rclone_mount_dir"; then {
      log::info "Trying to mount your cloud provider via rclone, executing ${BGREEN}filesync::mount_rclone${RC} function";
      filesync::mount_rclone || {
        log::error "It looks like something went wrong, try again and edit your profile to fix it" 1 || exit;
      };
    } fi

    log::info "Your setup is now complete";
    log::info "Run ${BGREEN}${___self} filesync save --help${RC} to learn about usage";
  }

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
      rclone)
        cli::rclone "$@";
        ;;
      * | wizard)
        shift || true;
        cli::wizard "$@";
        ;;
    esac

    exit;
}
