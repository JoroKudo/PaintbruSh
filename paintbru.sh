#!/bin/bash

IFS=''

declare readonly -i height=$(($(tput lines) - 5)) width=$(($(tput cols) - 2))

declare -i head_r head_c
declare -i head_rtemp head_ctemp
declare body
declare matrix
colornr=2
declare -i direction delta_dir
icon=""
border_color="\e[0;34;47m"
brush_color="\e[32;42m"
no_color="\e[0m"
tile_color="\e[0m"
coloreto="\e[0;31;47m"

move_r=([0]=-1 [1]=0 [2]=1 [3]=0)
move_c=([0]=0 [1]=1 [2]=0 [3]=-1)

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

draw_board() {
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

  echo -e "$coloreto$coloreto"
  printf '\e[K'

  printf "\n"
  print_style $coloreto $coloreto " <[SPACE] LIFT/LOWER PEN>    <[1-7] COLORS>  <[0] ERASE>        CURRENT  "
  printf "$brush_color%b$coloreto\n" "   "

  print_style $coloreto $coloreto " <[H] LEFT>    <[J] DOWN>    <[K] UP>        <[L] RIGHT>         COLOR   "
  printf "$brush_color%b$coloreto\n" "   "
  printf '\e[K'

  printf " "

  echo
}
print_style() {

  printf '\e[K'

  printf "$1%b$2" "$3"

}
init_tools() {
  direction=0
  alive=0
  eraser=0

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

  tile_color="\e["$((90))";"$((40 + tile_color_index_new))"m"
  tile_color_symbol="\e["$((30 + tile_color_index))";"$((40 + tile_color_index))"m"
  if [ "$eraser" -eq 0 ]; then
    icon="■"
    eval "arr$1[$2]=\"${tile_color}■$no_color\""
    eval "arr$head_r[$head_c]=\"${brush_color}1$no_color\""
    eval "matrix$head_r[$head_c]=\"$((colornr))\""

  else
    icon="□"
    eval "arr$1[$2]=\"${tile_color}□$no_color\""
    eval "arr$head_r[$head_c]=\"${tile_color_symbol}1$no_color\""

  fi

  head_c=$head_ctemp
  head_r=$head_rtemp

}

change_dir() {

  direction=$1

  delta_dir=-1
}

draw_loop() {

  while [ "$alive" -eq 0 ]; do

    read -rsn1 key

    case "$key" in
    ["q"])
      kill -"$SIG_QUIT"
      return
      ;;

    ["k"])
      delta_dir=0
      ;;
    ["l"])
      delta_dir=1
      ;;
    ["j"])
      delta_dir=2
      ;;
    ["h"])
      delta_dir=3
      ;;

    \
      ["t"])

      for ((i = 1; i <= height; i++)); do

        for ((j = 1; j <= width; j++)); do
          eval echo -n "\"\${matrix$i[$j]}\""

        done

        echo
      done

      ;;
    [" "])
      if [ "$eraser" -eq 0 ]; then

        eraser=1
      else
        eraser=0
      fi

      ;;

    [0,1,2,3,4,5,6,7])
      colornr=$((key))
      change_color

      ;;
    esac
    if [ "$delta_dir" -ne -1 ]; then
      change_dir $delta_dir
      move_brush

    fi

    draw_board
    sleep 0.03
  done

  kill -"$SIG_DEAD" $$
}

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
