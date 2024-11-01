#!/bin/bash

# Define constants and variables
. brush.config
IFS=''
declare -r height=$(( $(tput lines) - 5 ))
declare -r width=$(( $(tput cols) - 2 ))
declare -i head_r head_c head_rtemp head_ctemp direction delta_dir
declare body matrix
declare -i colornr=2 filenr=0
icon=""
dialog=""
border_color="\e[0;34;47m"
brush_color="\e[32;42m"
no_color="\e[30;40m"
tile_color="\e[0m"
coloreto="\e[0;31;47m"
tile_color_fg=90
move_r=(-1 0 1 0)
move_c=(0 1 0 -1)
penpos1=0
penpos2=0

init_screen() {

  clear
  echo -ne "\e[?25l"
  stty -echo
  for ((i = 0; i < height - 2; i++)); do
    for ((j = 0; j < width; j++)); do

      eval "arr$i[$j]=' '"

      eval "matrix$i[$j]='0'"
    done

  done

}

move_and_draw() {

  echo -ne "\e[${1};${2}H$3"
}
draw_canvas_noborder() {

  for ((i = 0; i < height - 2; i++)); do
    eval echo -en "\"\${arr$i[*]}\""
    printf "$no_color%b$no_color" "  "
  done

}

draw_canvas() {
  move_and_draw 1 1 "$border_color+$no_color"
  for ((i = 2; i <= width + 1; i++)); do
    move_and_draw 1 "$i" "$border_color-$no_color"
  done
  move_and_draw 1 $((width + 2)) "$border_color+$no_color"
  echo

  for ((i = 0; i < height - 2; i++)); do
    move_and_draw $((i + 2)) 1 "$border_color|$no_color"
    eval echo -en "\"\${arr$i[*]}\""
    echo -e "$border_color|$no_color"
  done

  move_and_draw $((height)) 1 "$border_color+$no_color"
  for ((i = 2; i <= width + 1; i++)); do
    move_and_draw $((height)) "$i" "$border_color-$no_color"
  done
  move_and_draw $((height)) $((width + 2)) "$border_color+$no_color"

}
draw_ui() {
  echo -e "$coloreto$coloreto"
  printf '\e[K'

  printf "\n"
  print_style $coloreto $coloreto " <[SPACE] LIFT/LOWER PEN>    <[1-7] COLORS>  <[0] ERASE>   <[${EXPORT_KEY}] EXPORT>   CURRENT  "
  printf "$brush_color%b$coloreto\n" "   "

  print_style $coloreto $coloreto " <[${L_KEY}] LEFT>    <[${DOWN_KEY}] DOWN>    <[${UP_KEY}] UP>        <[${R_KEY}] RIGHT>                   COLOR   "
  printf "$brush_color%b$coloreto\n" "   "
  printf '\e[K'

  printf " $dialog"

  echo

}
draw_board() {
  draw_canvas
  draw_ui
}
print_style() {

  printf '\e[K'

  printf "$1%b$2" "$3"

}
init_tools() {
  direction=0
  hover=0

  delta_dir=-1

  head_rtemp=$((height / 2 - 2))
  head_ctemp=$((width / 2))

  body=''

  local p=${move_r[1]}
  local q=${move_c[1]}

  eval "arr$head_r[$head_c]=\"${brush_color}o$no_color\""

  prev_r=$head_r
  prev_c=$head_c

  b=$body
  while [ -n "$b" ]; do
    # change in each direction
    local p=${move_r[$(echo "$b" | grep -o '^[0-3]')]}
    local q=${move_c[$(echo "$b" | grep -o '^[0-3]')]}

    new_r=$((prev_r + p))
    new_c=$((prev_c + q))

    prev_r=$new_r
    prev_c=$new_c

    b=${b#[0-3]}
  done
}

move_brush() {

  local newhead_r=$((head_rtemp + move_r[direction]))
  local newhead_c=$((head_ctemp + move_c[direction]))

  head_ctemp=$newhead_c
  head_rtemp=$newhead_r
  show_brush $newhead_r $newhead_c
}

show_brush() {
  eval "local pos=\${arr$1[$2]}"

  tile_color_index="matrix$head_r[$head_c]"
  tile_color_index_new="matrix$1[$2]"

  tile_color="\e["$tile_color_fg";"$((40 + tile_color_index_new))"m"
  tile_color_symbol="\e["$((30 + tile_color_index))";"$((40 + tile_color_index))"m"

  if [ "$hover" -eq 0 ]; then
    icon="■"

    eval "arr$head_r[$head_c]=\"${brush_color}1$no_color\""
    eval "matrix$head_r[$head_c]=\"$((colornr))\""

  elif [ "$hover" -eq 1 ]; then
    icon="□"

    eval "arr$head_r[$head_c]=\"${tile_color_symbol}1$no_color\""

  fi
  eval "arr$1[$2]=\"${tile_color}$icon$no_color\""
  penpos1=$1
penpos2=$2
  head_c=$head_ctemp
  head_r=$head_rtemp

}

change_dir() {

  direction=$1

  delta_dir=-1
}
# Export drawing as an image
export_drawing() {
    mkdir -p $EXPORT_DIR
    FILE="${EXPORT_DIR}/drawingoutput"
    while [ -f "${FILE}.png" ]; do
        filenr=$((filenr+1))
        FILE="${EXPORT_DIR}/drawingoutput(${filenr})"
    done
    FILE="${FILE}.png"
    clear
    eval "arr$penpos1[$penpos2]=\"${tile_color} $no_color\""
    draw_canvas_noborder >/tmp/output.ansi
    ansilove -c $COLUMNS -o ${FILE} /tmp/output.ansi >/dev/null
    draw_board
    dialog="exported image"
    eval "arr$penpos1[$penpos2]=\"${tile_color}$icon$no_color\""
    draw_canvas
}
# Main drawing loop
draw_loop() {
    while true; do
        read -rsn1 key
        case "$key" in
            $QUIT_KEY) break ;;
            $UP_KEY) delta_dir=0 ;;
            $R_KEY) delta_dir=1 ;;
            $DOWN_KEY) delta_dir=2 ;;
            $L_KEY) delta_dir=3 ;;
            $EXPORT_KEY) export_drawing ;;
            " ") hover=$((1 - hover)) ;;
            [0-7]) colornr=$((key)); change_color ;;
        esac
        if [ "$delta_dir" -ne -1 ]; then
            change_dir $delta_dir
            move_brush
        fi
        draw_board
        sleep 0.03
    done
}

# Cleanup on exit
clear_app() {
    stty echo
    echo -e "\e[?25h"
}

change_color() {
  brush_color="\e["$((30 + colornr))";"$((40 + colornr))"m"

}

init_screen
init_tools
draw_board
draw_loop
clear_app
exit 0
