#!/bin/sh

# author: mathway

# Find file easily, and copy its path to the X clipboard.

DIR="$HOME"

[ "$#" -gt 0 -a -d "$1" -a -r "$1" ] && DIR="$1"

find "$DIR" | dmenu -l 25 -i | xclip -se clip -r
