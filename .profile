# .bash_profile
_locale_file=/etc/default/locale
if test -e $_locale_file; then
	set -a && source $_locale_file && set +a
else
	set -a
	LANG="en_US.UTF-8"
	LC_ALL="$LANG"
	LANGUAGE="$LANG"
	LC_CTYPE="$LANG"
	set +a
fi

# Re-set custom PATH
export PATH="$HOME/.local/bin:$PATH"

# Set default EDITOR
export EDITOR=nvim

# Get the aliases and functions
[ -f $HOME/.bashrc ] && . $HOME/.bashrc
