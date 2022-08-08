#!/bin/bash

prefix=$HOME/.local/bin

if [ -d "$prefix" ]; then
    mkdir -p "$prefix"
fi

ok=1
for f in ./*.sh; do
    [ $f = "./install.sh" ] && continue
    if ! ln -r -v -s "$f" "$prefix"/${f%.sh} 2>/dev/null; then
	ok=0
    fi
done

[ $ok = "0" ] && { echo "Failed to symlink some files." ; exit 1 ;}
