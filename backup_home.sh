#!/bin/bash

# author: mathway


# Awkward terminal color constants
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
    local opts
    declare -A opts # opts now is associative array
    printf "Usage: $(basename $0) [options...] -- [tar_options...]\n"
    opts["-c, --color"]="Presense of colors in output. 0 or 1."
    opts["-v, --verbose"]="Verbose output."
    opts["-d, --output-dir"]="Directory for backup storing."
    opts["-h, --help"]="Show this help menu."
    opts["-o, --output"]="Backup file path."
    opts["-i, --interactive, --nobatch"]="Be more interactive."
    opts["-b, --batch"]="Opposite of -i."
    opts["-t, --telegram"]="Save backup to telegram. !Unimplemented!"
    opts["-p, --passphrase"]="Passphrase for backup encryption."
    opts["-P, --passphrase-file"]="Read passphrase from file. If dash(-), read from stdin."
    opts["-e, --encrypt"]="Encrypt backup using symmetric cipher."
    for o in "${!opts[@]}"; do
	printf "\t%-30s\t%s\n" "$o" "${opts[$o]}"
    done
    printf "\nArguments after -- are treated as tar(1) options.\n"
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

clean_exit()
{
    shred -zfn3 "$tmpf" && rm -f "$tmpf"
    printf "%s\n" "Goodbye!"
    exit 0
}

debug_msg()
{
    maybe_color "$YELLOW_FG"
    [ "$LEVEL" -ge 2 ] && { printf "[DEBUG] " ; printf "$@" >&2; printf "\n" >&2; }
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

# Options
backupdir=/tmp
backupfile=
passphrase=

# Option parsing
while [ $# -gt 0 ]; do
    case $1 in
	-c|--color) shift
		    COLOR=$1
		    ;;
	-v|--verbose) LEVEL=2
		      tar_opts="$tar_opts -v"
		      ;;
	-h|--help) show_help
		   exit 0
		   ;;
	-d|--output-dir) shift
		      backupdir=$1
		      ;;
	-o|--output) shift
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
			      [ "$1" = "-" ] || 
			      [ -r "$1" -a -s "$1" ] &&
				  passphrase="$(cat $1)" ||
				      error "can't read from file \"$1\""
			      ;;
	-e|--encrypt) ENCRYPT=1
		    ;;
	--) shift # Remaining arguments are passed to tar as is.
	    break
	    ;;
	*) printf "Unrecognized option. Use -h for help.\n"
	   exit 1
	   ;;
    esac
    shift
done

if [ -z "$backupfile" ]; then
    backupfile=$backupdir/homebackup_$(date +%d-%m-%Y).tar.gz
fi

# exit in a clean way if SIGINT is sent
trap clean_exit SIGINT

{ touch "$backupfile" && chmod 600 "$backupfile" ;} || error "Can't create file"

rm "$backupfile"

tmpf=$(mktemp)
debug_msg "tmpf is $tmpf"
chmod 600 $tmpf

info_msg "Creating archive..."

cd $HOME
debug_msg "Backup file is %s" "$backupfile"
debug_msg "$tar_opts"
debug_msg "tmpfile is $tmpf"

# Pretty long exclusion list here, but it seems that this is the easier way
# to maintain rather than whitelisting.
# Compressing by default.

    
printf "%s" '
Desktop 
Downloads
QEMU*
.config/discord 
.mozilla*extensions
.wine
.terminfo
.face
.cache
.Xlog
.dbus
hacking/kali*
.npm
.gradle
.java
.local
.BurpSuite
.cargo
.ropper' | 
tar -hczSpf "$tmpf" --exclude-from - \
    --ignore-failed-read --ignore-command-error $tar_opts "$@" \
    --warning no-file-removed .* *

# Encrypt the backup file if user wants that.
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

# Move from temporary location to the user specified location.
mv "$tmpf" "$backupfile"

# Maybe somewhat paranoid, but why not
info_msg "Syncing..."
sync -f "$backupfile"

info_msg "Back up completed. Happy day/night!"
exit 0
