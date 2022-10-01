#!/bin/bash

# author: mathway

BLACK_FG='\033[01;30m'
RED_FG='\033[01;31m'
GREEN_FG='\033[01;32m'
YELLOW_FG='\033[01;33m'
BLUE_FG='\033[01;34m'
MAGENTA_FG='\033[01;35m'
CYAN_FG='\033[01;36m'
WHITE_FG='\033[01;37m'
DEFAULT_FG='\033[00m'


show_help()
{
    printf "Usage: $(basename $0) [-e|--encrypt] [-p passphrase] [-P passphrase_file] [-b|--batch] [-c|--color 0|1] [-h|--help] [-v|--verbose] -- [tar_options]\n"
}

maybe_color()
{
    [ "$COLOR" = "1" ] && printf "$1"
}

reset_color()
{
    [ "$COLOR" = "1" ] && printf "$DEFAULT_FG"
}

error()
{
    maybe_color "$RED_FG"
    printf "%s" "$@" >&2
    printf "\n" >&2
    printf "$DEFAULT_FG"
    reset_color
    exit 1
}

debug_msg()
{
    maybe_color "$YELLOW_FG"
    [ "$LEVEL" -ge 2 ] && { printf "[@] " ; printf "$@" >&2; printf "\n" >&2; }
    reset_color
}

info_msg()
{
    maybe_color "$BLUE_FG"
    [ "$LEVEL" -ge 1 ] && { printf "[*] " ; printf "$@" ; printf "\n" ; }
    reset_color
}


# flags
LEVEL=1
ENCRYPT=0
BATCH=0
COLOR=1

# parameters
backupdir=/tmp
backupfile=
passphrase=


while [ $# -gt 0 ]; do
    case $1 in
	-c|--color) shift
		    COLOR=$1
		    ;;
	-v|--verbose) LEVEL=2
		      tar_opts="$tar_opts -v"
		      ;;
	-d|--output-dir) shift
			 backupdir=$1
			 ;;
	-h|--help) show_help
		   exit 0
		   ;;
	-d|--output-dir) shift
		      backupdir=$1
		      ;;
	-f|--filename) shift
		       backupfile=$1
		       ;;
	-i|--interactive|--nobatch) BATCH=0
				    ;;
	-b|--batch) BATCH=1
		    COLOR=0
		    LEVEL=0
		    ;;
	-t|--telegram) error "Unimplemented option --telegram"
		    ;;
	-p|--passphrase) shift
			 passphrase=$1
			 ;;
	-P|--passphrase-file) shift
			      [ -r "$1" -a -s "$1" ] &&
				  passphrase="$(cat $1)" ||
				      error "can't read from file \"$1\""
			      ;;
	-e|--encrypt) ENCRYPT=1
		    ;;
	--) shift
	    break
	    ;;
	*) printf "Unrecognized option. Use -h for help.\n"
	   exit 1
	   ;;
    esac
    shift
done

while [ $# -gt 0 ]; do
    tar_opts="$tar_opts '$1'"
    shift
done

if [ -z "$backupfile" ]; then
    backupfile=$backupdir/homebackup_$(date +%d-%m-%Y).tar.gz
fi


{ touch "$backupfile" && chmod 600 "$backupfile" ;} || error "Can't create file"

rm "$backupfile"

tmpf=$(mktemp)
debug_msg "tmpf is $tmpf"
chmod 600 $tmpf

info_msg "Creating archive..."

cd $HOME
debug_msg "Backup file is %s" "$backupfile"
debug_msg "$tar_opts"
find . -maxdepth 1 -type f -print0 |
    tar --null --verbatim-files-from -T - --exclude "*~" --exclude '*kali_pentest*' --exclude '*config/discord'  --exclude '*mozilla*extensions' -hczSpf "$tmpf" docs hacking Music pics prog .gnupg .keepassxc .mozilla .config .emacs.d .john .ssh .local/bin $tar_opts 2>/dev/null

if [ "$ENCRYPT" = "1" ]; then
    if [ -z "$passphrase" ]; then
	read -p "Archive passphrase: " passphrase
    fi
    debug_msg "Passphrase is %s" "$passphrase"
    info_msg "Encrypting archive with secret passphrase..."
    printf "%s" "$passphrase" | gpg --yes --passphrase-fd 0 --batch -c "$tmpf"
    info_msg "Shredding temporary file..."
    shred "$tmpf" && rm -f "$tmpf"
    tmpf="${tmpf}.gpg"
    backupfile="${backupfile}.gpg"
fi

mv "$tmpf" "$backupfile"

info_msg "Syncing..."
sync -f "$backupfile"



info_msg "Back up completed. Happy day/night!"
exit 0
