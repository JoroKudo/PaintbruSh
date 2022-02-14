#!/bin/bash

IFS=''

declare -i height=$(($(tput lines)-5)) width=$(($(tput cols)-2))

# row and column number of head
declare -i head_r head_c 


declare -i length
declare body

declare -i direction delta_dir


border_color="\e[30;43m"
brush_color="\e[32;42m"
food_color="\e[34;44m"
text_color="\e[31;43m"
no_color="\e[0m"

# signals
SIG_UP=USR1
SIG_RIGHT=USR2
SIG_DOWN=URG
SIG_LEFT=IO
SIG_QUIT=SIGQUIT
SIG_DEAD=HUP
SIG_RED=WINCH

move_r=([0]=-1 [1]=0 [2]=1 [3]=0)
move_c=([0]=0 [1]=1 [2]=0 [3]=-1)

init_screen() {
    clear
    echo -ne "\e[?25l"
    stty -echo
    for ((i=0; i<height; i++)); do
        for ((j=0; j<width; j++)); do

            eval "arr$i[$j]=' '"
        done
    done
}

move_and_draw() {
    echo -ne "\e[${1};${2}H$3"
}

# print everything in the buffer
draw_board() {
    move_and_draw 1 1 "$border_color+$no_color"
    for ((i=2; i<=width+1; i++)); do
        move_and_draw 1 $i "$border_color-$no_color"
    done
    move_and_draw 1 $((width + 2)) "$border_color+$no_color"
    echo

    for ((i=0; i<height; i++)); do
        move_and_draw $((i+2)) 1 "$border_color|$no_color"
        eval echo -en "\"\${arr$i[*]}\""
        echo -e "$border_color|$no_color"
    done

    move_and_draw $((height+2)) 1 "$border_color+$no_color"
    for ((i=2; i<=width+1; i++)); do
        move_and_draw $((height+2)) $i "$border_color-$no_color"
    done
    move_and_draw $((height+2)) $((width + 2)) "$border_color+$no_color"
    echo
}

init_tools() {
    length=1
    direction=0
	    alive=0

    delta_dir=-1

    head_r=$((height/2-2))
    head_c=$((width/2))

    body=''
    for ((i=0; i<length-1; i++)); do
        body="1$body"
    done

    local p=$((${move_r[1]} * (length-1)))
    local q=$((${move_c[1]} * (length-1)))

  

    eval "arr$head_r[$head_c]=\"${brush_color}o$no_color\""

    prev_r=$head_r
    prev_c=$head_c

    b=$body
    while [ -n "$b" ]; do
        # change in each direction
        local p=${move_r[$(echo $b | grep -o '^[0-3]')]}
        local q=${move_c[$(echo $b | grep -o '^[0-3]')]}

        new_r=$((prev_r+p))
        new_c=$((prev_c+q))

        eval "arr$new_r[$new_c]=\"${brush_color}o$no_color\""

        prev_r=$new_r
        prev_c=$new_c

        b=${b#[0-3]}
    done
}





move_brush() {

    local newhead_r=$((head_r + move_r[direction]))
    local newhead_c=$((head_c + move_c[direction]))

    eval "local pos=\${arr$newhead_r[$newhead_c]}"
	eval "arr$newhead_r[$newhead_c]=\"${no_color}🖌$no_color\""
   	eval "arr$head_r[$head_c]=\"${brush_color}█$no_color\""
	head_c=$newhead_c
        head_r=$newhead_r
    local d=$(echo $body | grep -o '[0-3]$')
 
}

change_dir() {
 
        direction=$1
    
    delta_dir=-1
}

getchar() {
    trap "" SIGINT SIGQUIT
    trap "return;" $SIG_DEAD

    while true; do
        read -s -n 1 key
        case "$key" in
			[qQ]) kill -$SIG_QUIT $app_pid
                  return
                  ;;
            [rR]) kill -$SIG_RED $app_pid
                 ;;
            [kK]) kill -$SIG_UP $app_pid
                  ;;
            [lL]) kill -$SIG_RIGHT $app_pid
                  ;;
            [jJ]) kill -$SIG_DOWN $app_pid
                  ;;
            [hH]) kill -$SIG_LEFT $app_pid
                  ;;

       esac
    done
}

draw_loop() {
    trap "delta_dir=0;" $SIG_UP
    trap "delta_dir=1;" $SIG_RIGHT
    trap "delta_dir=2;" $SIG_DOWN
    trap "delta_dir=3;" $SIG_LEFT
    trap 'brush_color="\033[0;31m";' $SIG_RED
    trap "exit 1;" $SIG_QUIT

    while [ "$alive" -eq 0 ]; do
      

        if [ "$delta_dir" -ne -1 ]; then
            change_dir $delta_dir
			move_brush
			
        fi
        
        draw_board
        sleep 0.03
    done
    


    kill -$SIG_DEAD $$
}

clear_app() {
    stty echo
    echo -e "\e[?25h"
}

init_screen
init_tools

draw_board

draw_loop &
app_pid=$!
getchar

clear_app
exit 0
