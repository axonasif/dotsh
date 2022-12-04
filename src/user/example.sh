# To compile and use this module:
## Make sure that /src/user/mod.sh has `use example;` statement.
## Make sure /src/main.sh has `use user;` statement.
# Then You can call your module function(s) from `/src/main.sh` or somewhere else.

function user::example {
  # Call child functions of this module here.
  # Start them as a subprocess for concurrency with `&`.
  # Use `& disown` at the end of command to not wait for completion. (i.e. detach)

  example::create_something "# hello" "$HOME/.example.conf" & # Does not detach.
  example::remove_files & disown; # Detached, will not be wait'ed for.

  # Waits for `&` functions to complete
  wait $(jobs -rp); # `jobs -rp` returns [r]unning [p]rocess IDs
}

function example::create_something() {
  # Positional arguments
  declare input="$1";
  declare filepath="$2";

  # Create an file with $input contents. (overwrite mode)
  printf '%s\n' "${input}" > "${filepath}";
}

function example::remove_files {
  declare files=(
    "$HOME/.something"
    "/etc/zshrc"
  )

  sudo rm -rf "${files[@]}";
}
