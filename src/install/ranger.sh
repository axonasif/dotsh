function ranger::setup() {
	# Install ranger-fm
	bash -lic 'pip install --no-input ranger-fm' 1>/dev/null;
    local target=$HOME/.config/ranger/rc.conf;
    local target_dir="${target%/*}";
    local devicons_activation_string="default_linemode devicons";
    if ! grep -q "$devicons_activation_string" "$target" 2>/dev/null; then {
        mkdir -p "$target_dir";
        printf '%s\n' "$devicons_activation_string" >> "$target";
    } fi
    
    local devicons_plugin_dir="$target_dir/plugins/ranger_devicons";
    if test ! -e "$devicons_plugin_dir"; then {
        git clone --filter=tree:0 https://github.com/alexanderjeurissen/ranger_devicons "$devicons_plugin_dir";
    } fi
}