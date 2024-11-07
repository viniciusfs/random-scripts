#!/usr/bin/env bash

# Author: Vinicius Figueiredo <viniciusfs@gmail.com>

# Converts hexadecimal color code (ie. #ff5733) to 256 ANSI color code used in
# terminals. The 256 ANSI color pallete is structured as follows:
#
# - 0-15 are standard system colors.
# - 16-231 are RGB colors, defined by 6 values on each of three RGB axes.
# - 232-255 are grayscale starting from a shade slighly lighter than black,
#   ranging up to shade slighly darker than white.
#
# Instead of values 0-255, each RGB color only ranges from 0-5. The following
# expression calculates the color number:
#
# number = 16 + 36 * R + 6 * G + B
#
# Before using RGB numbers directly on this formula, we need to scale down each
# one from 0-255 RGB range to 0-5 ANSI range. The mapping used by XTerm and
# other terminals are:
#
# - ANSI range [0, 1,  2,   3,   4,   5]
# - RGB range  [0, 95, 135, 175, 215, 255]
#
# To achieve this we will assign the value as 0 if the number is less than 75,
# otherwise, we will reduce it by 35 and divide by 40.
#
# scaled_number = 0 if number < 75 else (number - 35) / 40
#
# References:
# - https://stackoverflow.com/questions/27159322/rgb-values-of-the-colors-in-the-ansi-extended-colors-index-17-255
#
# To set 256 ANSI colors use the following escape codes:
#
# - Set foreground color: ESC[38;5;{NUMBER}m
# - Set background color: ESC[48;5;{NUMBER}m
#
# To represent the escape ESC character in bash scripts you can use: the literal
# \e or \E, octal \033, hexadecimal \x1b and unicode \u1b or \U1b. Each
# programming language has it's own method of representing the escape character.
#
# Modern terminals supports truecolor (24-bit RGB), which allows to set colors
# using RGB directly and making almost everything here useless! LOL
#
# - Set foreground color: ESC[38;2;{R};{G};{B}m
# - Set background color: ESC[48;2;{R};{G};{B}m
#

hex_to_rgb() {
  hex="$1"
  r=$((16#${hex:1:2}))
  g=$((16#${hex:3:2}))
  b=$((16#${hex:5:2}))
  echo "$r $g $b"
}

scale_color() {
  if (( $1 < 75 )); then
    echo 0
  else
    echo $(( ($1 - 35) / 40))
  fi
}

rgb_to_ansi() {
  r=$(scale_color "${1}")
  g=$(scale_color "${2}")
  b=$(scale_color "${3}")
  echo "$((16+36*r+6*g+b))"
}

print_ansi() {
  rgb=$(hex_to_rgb "${1}")
  ansi=$(rgb_to_ansi "${rgb}")
  echo "Hex code: ${1}"
  echo "256 ANSI code: ${ansi}"
  echo "To set as foreground color: \e[38;5;${ansi}m"
  echo "To set as background color: \e[48;5;${ansi}m"
  echo -e "\e[38;5;${ansi}mExample text\e[0m"
  echo -e "\e[48;5;${ansi}m            \e[0m"
}

print_rgb() {
  rgb=($(hex_to_rgb "${1}"))
  echo "Hex code: ${1}"
  echo "RGB code: ${rgb[*]}"
  echo "To set as foreground color: \e[38;2;${rgb[0]};${rgb[1]};${rgb[2]}m"
  echo "To set as background color: \e[48;2;${rgb[0]};${rgb[1]};${rgb[2]}m"
  echo -e "\e[38;2;${rgb[0]};${rgb[1]};${rgb[2]}mExample text\e[0m"
  echo -e "\e[48;2;${rgb[0]};${rgb[1]};${rgb[2]}m            \e[0m"
}

print_usage() {
  cat << EOF
hex2ansi.sh - Converts hex color codes to 256 ANSI color codes.

Usage: $0 [hexcode] [-r hexcode] [-t] [-h]
EOF
}

print_ansi_table() {
  for red in {0..5}; do
    for green in {0..5}; do
      for blue in {0..5}; do
        color=$((16+36*red+6*green+blue))
        echo -ne "\e[48;5;${color}m    \e[0m"
      done
    done
  done
}

PRINT_ANSI=true
PRINT_TABLE=""
PRINT_RGB=""

while getopts "r:th" OPT; do
  case "${OPT}" in
    r)
      PRINT_ANSI=false
      PRINT_RGB=true
      HEXCODE=${OPTARG}
      ;;
    t)
      PRINT_ANSI=false
      PRINT_TABLE=true
      ;;
    h|*)
      print_usage
      exit 0
      ;;
  esac
done

if [[ -n ${PRINT_TABLE} ]]; then
  print_ansi_table
fi

if [[ -n ${PRINT_RGB} ]]; then
  print_rgb "${HEXCODE}"
fi

shift $((OPTIND - 1))
if $PRINT_ANSI && [[ -n $1 ]]; then
  print_ansi "${1}"
fi

if $PRINT_ANSI && [[ -z $1 ]]; then
  print_usage
fi
