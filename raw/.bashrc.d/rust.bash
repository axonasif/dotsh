rust_env_file="$HOME/.cargo/env";

if test -e "$rust_env_file"; then {
  source "$rust_env_file";
} fi

unset rust_env_file;
