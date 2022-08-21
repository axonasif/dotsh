homebrew_dir="/opt/homebrew";
if test -e "$homebrew_dir"; then {
  eval "$("$homebrew_dir"/bin/brew shellenv)";
} fi
unset homebrew_dir;
