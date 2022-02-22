#!/bin/sh

# Thanks to BugsWriter

tmpf=`mktemp`
xclip -se clip -o > $tmpf
curl -F "file=@$tmpf" '0x0.st' 2>/dev/null | xclip -se clip -r
rm $tmpf
