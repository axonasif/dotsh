# Re-set custom PATH
local_bin_dir="$HOME/.local/bin";
if test -e "$local_bin_dir"; then {
  export PATH="$HOME/.local/bin:$PATH";
} fi
unset local_bin_dir;

# Set default EDITOR
export EDITOR=nvim;

# Set USER if missing
: "${USER:=axon}" && export USER;

# Disable nullglob
shopt -s nullglob

for script in "$HOME/.bashrc.d"/*; do {
  source "$script";
} done
source "/Users/axon/.bashbox/env";
