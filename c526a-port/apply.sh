#!/bin/sh
#
# Apply HiWiFi C526A board support on top of a clean OpenWrt tree.
#
# Usage: ./apply.sh <main|2410|2512> [path-to-openwrt]
#
#   main  - openwrt/openwrt main, immortalwrt/immortalwrt, coolsnowwolf/lede
#           (all three use kernel 6.18 and target/linux/ipq40xx/dts/)
#   2410  - openwrt/openwrt openwrt-24.10 (kernel 6.6, files-6.6/arch/.../dts)
#   2512  - openwrt/openwrt openwrt-25.12 (kernel 6.12, files-6.12/arch/.../dts)
#
set -eu

SRC_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE=${1:-main}
OWRT_DIR=${2:-openwrt}

case "$SOURCE" in
main|2410|2512) ;;
*)
	echo "error: unknown source '$SOURCE' (use main, 2410 or 2512)" >&2
	exit 1
	;;
esac

if [ ! -d "$OWRT_DIR/target/linux/ipq40xx" ]; then
	echo "error: $OWRT_DIR does not look like an OpenWrt tree" >&2
	exit 1
fi

cd "$OWRT_DIR"

for p in "$SRC_DIR/patches/$SOURCE"/*.patch; do
	echo "==> applying $(basename "$p")"
	git apply --check "$p"
	git apply "$p"
done

echo "==> installing common board files"
cp -a "$SRC_DIR/files/common/." .

echo "==> installing $SOURCE board files"
cp -a "$SRC_DIR/files/$SOURCE/." .

echo "==> done"
