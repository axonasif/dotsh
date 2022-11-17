function install::dotsh {
  try_sudo ln -sf "$___self_DIR/${___self##*/}" "/usr/bin/dotsh";
}
