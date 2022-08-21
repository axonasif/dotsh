#!/usr/bin/env bash


#UP_FORMAT=""
#if [ "$UP" -gt "999" ]; then
#  UP_FORMAT=$(echo $UP | awk '{ printf "%03.0f Mbps", $1 / 1000}')
#else
#  UP_FORMAT=$(echo $UP | awk '{ printf "%03.0f kbps", $1}')
#fi

data="$(ifstat -i "en0" 0.1 1 | awk 'NF == 2{print $1,$2}')";
down="${data%% *}" && up="${data##* }"

sketchybar -m \
	--set network_down label="Rx: $down Kb" \
	--set network_up label="Tx: $up Kb"
