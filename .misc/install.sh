#!/bin/bash

set -eEuT
if test "$EUID" -ne 0; then {
	echo "ERROR: User is not root";
	exit 1;
} fi
_user_home="/home/axon";
_misc_dir="$_user_home/.misc";
mkdir -p -m 0755 /etc/X11/tigervnc /usr/share/xsessions;
ln -srf "$_user_home/.xinitrc" /etc/X11/tigervnc/Xsession;
ln -srf "$_misc_dir/dwm.desktop" /usr/share/xsessions/dwm.desktop;
ln -srf "$_misc_dir/xorg.conf" /etc/X11/xorg.conf;
ln -srf "$_misc_dir/Xwrapper.config" /etc/X11/Xwrapper.config;
#chmod 755 "$_misc_dir/vncserver_wrapper" && ln -sf "$_misc_dir/vncserver_wrapper" /usr/bin/vncserver_wrapper;
