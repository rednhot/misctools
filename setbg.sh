#!/bin/sh

# Script that automatically generates color
# schemes and recompiles gui apps, depending on the selected wallpaper.
#
# Thanks to BugsWriter's video: https://www.youtube.com/watch?v=g8_d2rnwQdo

if [ $# -eq 1 -a -f "$1" ]; then
    wall="$1"
else
    echo "Choosing a random wallpaper..."
    wall="$(find $HOME/pics/wals -type f | shuf -n 1)"	
fi
    

echo "Setting up a wallpaper..."
echo "$wall" > ~/.last_wallpaper_path
xwallpaper --zoom "$wall"

echo "Generating pywal color schemes..."
wal -i "$wall" > /dev/null
sed -i 'N;$!P;D' $HOME/.cache/wal/colors-wal-dwm.h

echo "Recompiling dwm with new colors..."

cd $HOME/.local/src/dwm && make clean install
cd $HOME/.local/src/st && make clean install
cd $HOME/.local/src/dmenu && make clean install

