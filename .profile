# .bash_profile
# is used for interactive login shells
# .bashrc is used for non-login interactive shells

if test -e /proc && test -e /sys; then {
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
} fi

# Get the aliases and functions
[ -f $HOME/.bashrc ] && . $HOME/.bashrc
