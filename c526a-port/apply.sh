#!/bin/sh
#
# Apply HiWiFi C526A board support on top of a clean OpenWrt tree.
#
# Usage: ./apply.sh [path-to-openwrt]
#
set -eu

SRC_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OWRT_DIR=${1:-openwrt}

if [ ! -d "$OWRT_DIR/target/linux/ipq40xx" ]; then
	echo "error: $OWRT_DIR does not look like an OpenWrt tree" >&2
	exit 1
fi

cd "$OWRT_DIR"

for p in "$SRC_DIR"/patches/*.patch; do
	echo "==> applying $(basename "$p")"
	git apply --check "$p"
	git apply "$p"
done

echo "==> installing board files"
cp -a "$SRC_DIR"/files/. .

echo "==> done"
