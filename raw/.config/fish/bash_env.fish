#!/usr/bin/fish

set blacklist_regex '^(SHLVL|PWD|SHELL|PS1|OLDPWD|LS_COLORS|BASH_FUNC.*|_)';

bash -lc env | while read -d = -l name value
	if string match --quiet --regex --invert "$blacklist_regex" "$name";
		set -gx "$name" "$value";
	end
end