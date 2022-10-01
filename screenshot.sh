#!/bin/sh

# author: mathway

# SYNOPSIS
# screenshot.sh [-d dir | -p] [-h]
#
# DESCRIPTION
#    Wrapper script that can create screenshots.
#  
# OPTIONS
#        -p        Use area instead of whole screen.
#        -f        Use full screen screenshot. (Default)
#        -c        Place image in clipboard.   (Default)
#        -d dir    Use specified directory as storage
#                  for a screenshot.
#        -o path   Full path of saved file.
#        -h        Show help.
#
# EXAMPLES
# screenshot.sh -d /home/$LOGNAME/kartinki -p
# screenshot.sh -p
# screenshot.sh

err() {
    [ $# -gt 0 ] && echo "$*" || echo "Can't take screenshot for some unknown reason."
    exit 1
}

show_help() {
    echo "screenshot.sh [-d dir | -p] [-h]\n"
}

check_dependencies() {
    echo "check_dependencied is not implemented yet :(" >&2
}

SAVE_DIR=
SAVE_PATH=
FULL_SCREEN=1
while getopts d:pfco:h opt
do
    case $opt in
	d) SAVE_DIR="$OPTARG" ;;
	p) FULL_SCREEN=0 ;;
	f) ;; # Emtpy since is default.
	c) ;; # Empty since is default.
	o) SAVE_PATH="$OPTARG" ;;
	h) show_help
	   exit 0 ;;
	*) show_help
	   exit 1 ;;
    esac
done

[ -n "$SAVE_DIR" -a -n "$SAVE_PATH" ] && err "Use one of \`-d' and \`-o' option."

if [ -n "$SAVE_PATH" -o -n "$SAVE_DIR" ]; then
    OUT_PATH=
    [ -d "$SAVE_DIR" -a -w "$SAVE_DIR" -a -x "$SAVE_DIR" ] && OUT_PATH="$SAVE_DIR"/Screenshot\ "`date '+%b %d %H:%M:%S %Y'`".png ||
	     { touch "$SAVE_PATH" && OUT_PATH="$SAVE_PATH" ;} 2>/dev/null ||
		    err "Destination is not eligible."

    if [ "$FULL_SCREEN" -eq 1 ]; then
	import -window root "$OUT_PATH" || err
    else
	import "$OUT_PATH" || err
    fi
else
    tmpf=`mktemp`
    mv "$tmpf" "$tmpf".png
    tmpf="$tmpf".png
    
    if [ "$FULL_SCREEN" -eq 1 ]; then
	import -window root "$tmpf" || err
    else
	import "$tmpf" || err
    fi
    xclip -se clip -t image/png -i "$tmpf"
    rm "$tmpf"
fi
