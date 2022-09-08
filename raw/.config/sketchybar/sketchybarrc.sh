# This is a demo config to bring across some of the most important commands more easily.
# For a more advanced configuration example see https://github.com/FelixKratz/SketchyBar/discussions/47#discussion-3587958
_sketchybar_plugdir="$HOME/.config/sketchybar/plugins";
_break_rem_file=/tmp/.first_break_rem;
############## BAR ############## 
sketchybar  --bar height=25        \
                    blur_radius=50   \
                    position=top     \
                    padding_left=10  \
                    padding_right=10 \
                    color=0x44000000

############## GLOBAL DEFAULTS ############## 
sketchybar  --default updates=when_shown                    \
                        drawing=on                            \
                        cache_scripts=on                      \
                        icon.font="Hack Nerd Font:Bold:20.0"  \
                        icon.color=0xffffffff                 \
                        label.font="Hack Nerd Font:Bold:14.0" \
                        label.color=0xffffffff

############## SPACE DEFAULTS ############## 
sketchybar  --default label.padding_left=2  \
                        label.padding_right=2 \
                        icon.padding_left=2   \
                        label.padding_right=2

############## PRIMARY DISPLAY SPACES ############## 
sketchybar  --add space one left                              \
              --set one  associated_display=1                    \
                         associated_space=1                      \
                         icon=                                  \
                         icon.highlight_color=0xfffab402         \
              --add space two left                               \
              --set two  associated_display=1                    \
			 associated_space=2                      \
                         icon=                                  \
                         icon.highlight_color=0xfffab402         \
              --add space three left                               \
              --set three  associated_display=1                    \
			 associated_space=3                      \
                         icon=                                  \
                         icon.highlight_color=0xfffab402         \
              --add space four left                               \
              --set four  associated_display=1                    \
			 associated_space=4                      \
                         icon=                                  \
                         icon.highlight_color=0xfffab402         \
              --add space five left                               \
              --set five  associated_display=1                    \
			 associated_space=5                      \
                         icon=                                  \
                         icon.highlight_color=0xfffab402         \
              --add space six left                               \
              --set six  associated_display=1                    \
			 associated_space=6                      \
                         icon=                                  \
                         icon.highlight_color=0xfffab402         \






############## SECONDARY DISPLAY SPACES ############## 
sketchybar  --add space misc left                              \
              --set misc associated_display=2                    \
                         associated_space=5                      \
                         icon.font="Hack Nerd Font:Bold:20.0"    \
                         icon=                                  \
                         icon.highlight_color=0xff48aa2a         \
                         label=misc                              \
                         click_script="yabai  space --focus 5"

############## ITEM DEFAULTS ###############
sketchybar  --default label.padding_left=2  \
                        icon.padding_right=2  \
                        icon.padding_left=6   \
                        label.padding_right=6


############## LEFT ITEMS ############## 
sketchybar --add item system.label left \
           --set system.label script='sketchybar --set $NAME label="$INFO"' \
           --subscribe system.label front_app_switched

sketchybar  --add item space_separator left                                                  \
              --set space_separator  icon=                                                    \
                                     associated_space=1                                        \
                                     icon.padding_left=15                                      \
                                     label.padding_right=15                                    \
                                     icon.font="Hack Nerd Font:Bold:15.0"
              
############## RIGHT ITEMS ############## 

 sketchybar  --add item clock right                                                                  \
               --set clock         update_freq=10                                                      \
                                   script="$_sketchybar_plugdir/clock.sh" --add item topmem left                                                           \
               --set topmem           associated_space=1                                        \
                                      icon.padding_left=10                                      \
                                      update_freq=15                                            \
                                      script="$_sketchybar_plugdir/topmem.sh"	

## MenuMeters
_meters=();
for meter in "MenuMeterNet" "MenuMeterMem" "MenuMeterCPU"; do {
  meters+=("--add" "alias" "MenuMeters,com.ragingmenace.${meter}" "right");
} done
sketchybar "${meters[@]}"

# 		--add item cpu_temp right \
# 		--set cpu_temp script='sketchybar --set cpu_temp label="$(temp_sensor)"' associated_display=1 update_freq=8 \
# 	--add item network_up right \
#               --set network_up label.font="Hack Nerd Font:Bold:10.0" \
#                                y_offset=5 \
#                                width=0 \
#                                update_freq=3 \
#                                script="$_sketchybar_plugdir/network.sh" \
# 			       associated_display=1 \
# \
#               --add item network_down right \
#               --set network_down label.font="Hack Nerd Font:Bold:10.0" \
#                                  y_offset=-4 \
# 				 associated_display=1 \
#                                  update_freq=3
# Creating Graphs
sketchybar --add item topproc right                                              \
              --set topproc      associated_space=1                                 \
                                 label.padding_right=10                             \
                                 update_freq=15                                     \
                                 script="$_sketchybar_plugdir/topproc.sh" 
###################### CENTER ITEMS ###################


###################### Background non-ui scripts ################
# TakeABreak Reminder
#if test -z "$SDEBUG"; then {

#	sketchybar  --add item break_reminder \
 #       	      --set break_reminder script="test ! -e $_break_rem_file && touch $_break_rem_file || pmset displaysleepnow" update_freq=1500
#} fi

############## FINALIZING THE SETUP ##############
sketchybar  --update

echo "sketchybar configuration loaded.."
