function install::ranger() {
	# Install ranger-fm
    if ! command::exists pip3; then {
        log::error "Python not installed" 1 || exit;
    } fi
	bash -lic 'pip3 install --no-input ranger-fm' 1>/dev/null;
    local target=$HOME/.config/ranger/rc.conf;
    local target_dir="${target%/*}";

	# Ranger config
    local devicons_activation_string="default_linemode devicons";
    if ! grep -q "$devicons_activation_string" "$target" 2>/dev/null; then { # If the config doesn't exist
        mkdir -p "$target_dir";
        printf '%s\n' "$devicons_activation_string" >> "$target";
    } fi
    
	# Devicons plugin for ranger
    local devicons_plugin_dir="$target_dir/plugins/ranger_devicons";
    if test ! -e "$devicons_plugin_dir"; then { # If the devicons plugin doesn't exist 
        git clone --filter=tree:0 https://github.com/alexanderjeurissen/ranger_devicons "$devicons_plugin_dir" > /dev/null 2>&1;
    } fi
}
