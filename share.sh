#!/bin/sh

DIR="$HOME"

[ "$#" -gt 0 -a -d "$1" -a -r "$1" ] && DIR="$1"

curl -F "file=@$(find "$DIR" | dmenu -l 25 -i)" '0x0.st' 2>/dev/null | xclip -se clip -r
