#!/usr/bin/bash
# set -x; exec 2>/tmp/log#
# run 'tr ';\n' '; ' < vscode_tmux_test.sh | xargs' to export#

tmux new-session -ds main 2>/dev/null || :;
if cpids="$(tmux list-clients -t main -F '#{client_pid}')"; then
	for cpid in $cpids; do
		spid=$(ps -o ppid= -p $cpid);
		[ ${spid:-} == "$PPID" ] && attach=false && break;
	done;
fi;
[ "${attach:-}" != false ] && exec tmux attach -t main;
exec tmux new-window -n "vs:${PWD##*/}" -t main