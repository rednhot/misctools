#!/bin/sh

[ "$#" -eq 1 ] || { echo "Usage: $(basename $0) <file.md>" ; exit 1;}

grip --export "$1" "${1/%md/html}"
wkhtmltopdf "${1/%md/html}" "${1/%md/pdf}"
