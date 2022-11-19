function install::dotsh {
  try_sudo ln -sf "$___self_DIR/${___self##*/}" "/usr/bin/dotsh";
}

function dotsh::cli() {
  case "${1:-}" in
    livetest)
      shift || true;
      declare cmd=(
        bashbox -C "$(get::dotfiles-sh_dir)" livetest ws "$@"
      )
      log::info "Executing ${cmd[*]}";
      "${cmd[@]}";
      ;;
    esac
}