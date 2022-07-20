function ranger::setup() {
    local target=$HOME/.config/ranger/rc.conf;
    local target_dir="${target%/*}";
    local devicons_activation_string="default_linemode devicons";
    if ! grep -q "$devicons_activation_string" "$target" 2>/dev/null; then {
        mkdir -p "$target_dir";
        printf '%s\n' "$devicons_activation_string" >> "$target";
    } fi
    
    local devicons_plugin_dir="$target_dir/plugins/ranger_devicons";
    if test ! -e "$devicons_plugin_dir"; then {
        git clone https://github.com/alexanderjeurissen/ranger_devicons;
    } fi
}