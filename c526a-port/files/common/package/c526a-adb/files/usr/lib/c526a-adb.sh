#!/bin/sh
#
# Shared helpers for the c526a-adb CGI scripts and command-line tools.
#

# Percent-decode a URL query value ("+" becomes a space).
urldecode() {
	local s="$1"
	s="${s//+/ }"
	printf '%b' "${s//%/\\x}"
}

# Stable file-name component for an ADB serial (":" and "/" are unsafe).
safe_serial() {
	printf '%s' "$1" | tr ':/' '__'
}

# busybox on OpenWrt has no "timeout" applet; fall back to a small wrapper.
adb_timeout() {
	local secs="$1"
	shift
	local p w rc
	if command -v timeout >/dev/null 2>&1; then
		timeout "$secs" "$@"
		return
	fi
	"$@" &
	p=$!
	(sleep "$secs"; kill "$p" 2>/dev/null) >/dev/null 2>&1 &
	w=$!
	wait "$p"
	rc=$?
	kill "$w" 2>/dev/null
	return "$rc"
}

# Authorized ADB serials, one per line.
adb_serials() {
	/usr/bin/adb devices 2>/dev/null |
		awk 'NR > 1 && $2 == "device" { print $1 }'
}

# Run a content query as the shell UID, falling back to su only when the
# provider denies it.  The query is passed as one argv: adb 1.0.32 keeps an
# interactive shell alive when the command arrives on stdin.
content_query() {
	local uri="$1" projection="$2" sort="$3" where="$4" q out sup

	q="content query --uri $uri --projection $projection"
	[ -n "$where" ] && q="$q --where \"$where\""
	[ -n "$sort" ] && q="$q --sort \"$sort\""
	out=$(adb_timeout 30 adb -s "$DEV" shell "$q" 2>&1 | tr -d '\r\000')
	case "$out" in
	*"Error while accessing provider"*|*"Permission Denial"*|*"SecurityException"*)
		sup=$(adb_timeout 30 adb -s "$DEV" shell "su -c '$q'" 2>/dev/null | tr -d '\r\000')
		case "$sup" in
		*"Row: "*) out="$sup" ;;
		esac
		;;
	esac
	printf '%s\n' "$out"
}
