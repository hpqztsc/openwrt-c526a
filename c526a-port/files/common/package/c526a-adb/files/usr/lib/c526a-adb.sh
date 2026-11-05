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
