#!/bin/sh
#
# Author: alhazred
# Copyleft: 2024
#
# POSIX SHELL TODAY, POSIX SHELL TOMORROW, POSIX SHELL FOREVER.
# ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣧⣶⣶⣶⣦⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⣠⣾⢿⣿⣿⣿⣏⠉⠉⠛⠛⠿⣷⣕⠀⠀⠀⠀⠀⠀⢀⡀
# ⠀⠀⠀⠀⣠⣾⢝⠄⢀⣿⡿⠻⣿⣄⠀⠀⠀⠀⠈⢿⣧⡀⣀⣤⡾⠀⠀⠀
# ⠀⠀⠀⢰⣿⡡⠁⠀⠀⣿⡇⠀⠸⣿⣾⡆⠀⠀⣀⣤⣿⣿⠋⠁⠀⠀⠀⠀
# ⠀⠀⢀⣷⣿⠃⠀⠀⢸⣿⡇⠀⠀⠹⣿⣷⣴⡾⠟⠉⠸⣿⡇⠀⠀⠀⠀⠀
# ⠀⠀⢸⣿⠗⡀⠀⠀⢸⣿⠃⣠⣶⣿⠿⢿⣿⡀⠀⠀⢀⣿⡇⠀⠀⠀⠀⠀
# ⠀⠀⠘⡿⡄⣇⠀⣀⣾⣿⡿⠟⠋⠁⠀⠈⢻⣷⣆⡄⢸⣿⡇⠀⠀⠀⠀⠀
# ⠀⠀⠀⢻⣷⣿⣿⠿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠻⣿⣷⣿⡟⠀⠀⠀⠀⠀⠀
# ⢀⣰⣾⣿⠿⣿⣿⣾⣿⠇⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣿⣅⠀⠀⠀⠀⠀⠀
# ⠀⠰⠊⠁⠀⠙⠪⣿⣿⣶⣤⣄⣀⣀⣀⣤⣶⣿⠟⠋⠙⢿⣷⡄⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⢀⣿⡟⠺⠭⠭⠿⠿⠿⠟⠋⠁⠀⠀⠀⠀⠙⠏⣦⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⢸⡟⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#
# LOOK FOR OUR LOCAL OUTLET STORES WHEREVER YOU SEE THIS SIGN


fatal() {
	echo "Fatal: $@" >&2 
	exit 1
}


parse_error(){
	echo "Error: $@" >&2
	echo "" >&2
	usage
}

usage(){
	echo "dump_amass.sh: dump amass info from sqlite file"
	echo "- Author: alhazred"
	echo "- Source: https://github.com/dirtyfilthy/dump_amass"
	echo ""
	echo "Usage: $0 [-a] [-d SUFFIX] [-i] | [-e] [-4] | [-6] <amass.sqlite>"
	echo 
	echo "  -d SUFFIX    only show domains ending with SUFFIX"
	echo "  -a           only show matches with an A record"
	echo "  -i           internal, only show domains that resolve to a private IP range (implies -a)"
	echo "  -e           external, only show domains that are internet routable (implies -a)"
	echo "  -4           only show IPv4 addresses (implies -a)"
	echo "  -6           only show IPv6 addresses (implies -a)"
	echo "  -h           show this help"
	echo "<amass.sqlite> amass sqlite file"
	echo ""
	echo "Note: requires sqlite3 >= 3.45.0"
	exit 1
}

# check sqlite version is equal greater oto required version 
check_sqlite_version(){
	_MAJOR_VERSION_REQUIRED=$1
	_MINOR_VERSION_REQUIRED=$2
	_REQUIRED_VERSION="$_MAJOR_VERSION_REQUIRED.$_MINOR_VERSION"
	_SQLITE_VERSION_STRING=$(sqlite3 --version | cut -f 1 -d ' ')
	_SQLITE_MAJOR_VERSION=$(echo $_SQLITE_VERSION_STRING | cut -d '.' -f 1)
	_SQLITE_MINOR_VERSION=$(echo $_SQLITE_VERSION_STRING | cut -d '.' -f 2)

	if [ $_SQLITE_MAJOR_VERSION -lt $_MAJOR_VERSION_REQUIRED ]; then 
		parse_error "sqlite3 version $_SQLITE_VERSION_STRING is too old, $_REQUIRED_VERSION or greater required"
	elif [ $_SQLITE_MAJOR_VERSION -eq $_MAJOR_VERSION_REQUIRED ] && [ $_SQLITE_MINOR_VERSION -lt $_MINOR_VERSION_REQUIRED ]; then
		parse_error "sqlite3 version $_SQLITE_VERSION_STRING is too old,  $_REQUIRED_VERSION or greater required"
	fi
	return 0
}


# determine if an IPv4 or IPv6 comes from a RFC 1918 or RFC 4193 range
is_internal_ip(){
	_IP="$1"
	case $_IP in
		10.*) return 0 ;;
		192.168.*) return 0 ;;
		172.16.*) return 0 ;;
		172.17.*) return 0 ;;
		172.18.*) return 0 ;;
		172.19.*) return 0 ;;
		172.20.*) return 0 ;;
		172.21.*) return 0 ;;
		172.22.*) return 0 ;;
		172.23.*) return 0 ;;
		172.24.*) return 0 ;;
		172.25.*) return 0 ;;
		172.26.*) return 0 ;;
		172.27.*) return 0 ;;
		172.28.*) return 0 ;;
		172.29.*) return 0 ;;
		172.30.*) return 0 ;;
		172.31.*) return 0 ;;
		169.254.*) return 0 ;;
		127.*) return 0 ;;
		::1) return 0 ;;
		fe80:*) return 0 ;;
		fc00:*) return 0 ;;
		fd00:*) return 0 ;;
	esac
	return 1

}
# parse options

OPTSTRING=":ad:ie46h"
while getopts $OPTSTRING opt; do
	case $opt in
		a) A_ONLY=1 ;;
		d) SUFFIX=$OPTARG ;;
		i) INTERNAL=1; A_ONLY=1 ;;
		e) EXTERNAL=1; A_ONLY=1 ;;
		4) IPV4=1; A_ONLY=1 ;;
		6) IPV6=1; A_ONLY=1 ;;
		h) usage ;;
		:) parse_error "Option -$OPTARG requires an argument." ;;
		\?) parse_error "Invalid option: $OPTARG" ;;
	esac
done
shift $((OPTIND-1))
SQLITE_FILE=$1

# check options for sanity

[ -z "$(command -v sqlite3)" ] && parse_error "sqlite3 is not installed"

check_sqlite_version 3 45

[ -z "$SQLITE_FILE" ] && parse_error "must supply a sqlite file"
[ -n "$INTERNAL" ] && [ -n "$EXTERNAL" ] && parse_error "-i and -e are mutually exclusive options"
[ -n "$IPV4" ] && [ -n "$IPV6" ] && parse_error "-4 and -6 are mutually exclusive options"
[ -f "$SQLITE_FILE" ] || fatal "File $SQLITE_FILE not found"


# construct sql

EXTRA_CONSTRAINTS=""

if [ -n "$A_ONLY" ]; then 
	EXTRA_CONSTRAINTS="$EXTRA_CONSTRAINTS AND address.content->>'address' IS NOT NULL"
fi

if [ -n "$IPV4" ]; then
	EXTRA_CONSTRAINTS="$EXTRA_CONSTRAINTS AND address.content->>'type' = 'IPv4'"
elif [ -n "$IPV6" ]; then
	EXTRA_CONSTRAINTS="$EXTRA_CONSTRAINTS AND address.content->>'type' = 'IPv6'"
fi

SQL_QUERY=$(cat <<EOF
SELECT domain.content->>'name' AS fqdn, address.content->>'address' AS ip 
FROM assets AS domain 
LEFT JOIN relations on domain.id = relations.from_asset_id AND relations.type IN ('a_record', 'aaaa_record') 
LEFT JOIN assets AS address ON address.id = relations.to_asset_id
WHERE domain.type = 'FQDN' AND fqdn LIKE '%$SUFFIX' $EXTRA_CONSTRAINTS
EOF
)
sqlite3 $SQLITE_FILE "$SQL_QUERY" | (while read LINE; do
	DOMAIN=$(echo $LINE | cut -d '|' -f 1)
	IP=$(echo $LINE | cut -d '|' -f 2)
	if [ -n "$EXTERNAL" ] && is_internal_ip "$IP"; then 
		continue;
	elif [ -n "$INTERNAL" ] && ! is_internal_ip "$IP"; then
		continue;
	fi 
	printf "%-45s %s\n" "$DOMAIN" "$IP"
done)