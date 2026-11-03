# HiWiFi C526A (极路由 X) — multi-source OpenWrt port

Board support for the HiWiFi C526A (IPQ4019 + MT7615E) on top of the popular
current OpenWrt trees, plus a ready-to-use package selection.

This is **not** a driver port: `ath10k`, `mt7615e`, the ESS/DSA switch, the
QCOM NAND controller, `dwc3` and the PCIe host are all upstream. What is added
is the per-board data (DTS, image definition, 24 KB QCA4019 BDF, network/MAC
glue).

## Supported sources

| id | source | branch | kernel | notes |
|---|---|---|---|---|
| `main` | `openwrt/openwrt` | `main` | 6.18 | reference tree |
| `2410` | `openwrt/openwrt` | `openwrt-24.10` | 6.6 | stable; DTS under `files-6.6/` |
| `main` | `immortalwrt/immortalwrt` | `master` | 6.18 | patch applies unchanged |
| `main` | `coolsnowwolf/lede` | `master` | 6.18 | patch applies unchanged |
| — | `padavanonly/immortalwrt` | `master` | 5.4 | legacy, native support, no patch needed |

24.10 needs a slightly different DTS (old PCIe binding `perst-gpio`,
`qcom,ath10k-calibration-variant`), which is why there are two overlay sets.

## Layout

```
apply.sh                     apply a source variant to a clean tree
patches/main/                edits for 6.18-era trees
patches/2410/                edits for openwrt-24.10
files/common/                package + hotplug scripts (all trees)
files/main/                  DTS for 6.18 trees (target/linux/ipq40xx/dts)
files/2410/                  DTS for 24.10 (files-6.6/arch/arm/boot/dts/qcom)
config/common.config         shared package selection
config/<source>.config       target / device selection
```

## Package selection

`config/common.config` is built around what this box is good at — a small
wired/wireless router with a USB port:

**USB 接入网络 (USB WAN)**
`kmod-usb-net` + `cdc-ether` / `rndis` / `cdc-ncm` / `cdc-mbim` / `qmi-wwan` /
`ipheth`, `kmod-usb-serial-option`, `usb-modeswitch`, `umbim`, `uqmi`,
`comgt`, plus the LuCI protocol helpers (`luci-proto-qmi/mbim/ncm/3g`).
Covers Android/iPhone tethering, RNDIS/ECM dongles and QMI/MBIM LTE sticks.

**连接已有 WiFi 并作为 AP 转发**
`wpad-mbedtls` (full wpad), `travelmate` + `luci-app-travelmate`,
`relayd` + `luci-proto-relay`, `iw`, `iwinfo`.
The C526A has three radios (2× QCA4019 5 GHz + 1× MT7615E 2.4 GHz), so one
5 GHz radio can stay in STA mode while the other two serve clients.

**Storage / sharing**
USB storage + `ext4/vfat/exfat/ntfs3` + `block-mount`, `ksmbd-server` +
`luci-app-ksmbd`.

**Network services**
`dnsmasq-full`, `kmod-nft-offload` (software flow offload), `sqm-scripts`,
`ddns-scripts`, `miniupnpd-nftables`, `nlbwmon`, `etherwake` (WoL),
WireGuard, `ttyd` (web console).

**Tools**
`htop`, `curl`, `wget-ssl`, `nano`, `bash`, `usbutils`, `pciutils`,
`irqbalance`, `openssh-sftp-server`, Chinese LuCI translations.

**ADB host + SMS bridge**
`c526a-adb` (see below) on top of the in-tree `adb` package
(`package/utils/adb`, ADB 1.0.32). All four trees already ship it, so no
extra source is vendored. It is an older adb: no `adb pair` (Android 11+
wireless debugging) and no `exec-out`; `adb-ctl` falls back to
`screencap` + `adb pull`.

If the image does not fit the stock 44 MB `ubi` partition, drop `ksmbd`,
`wireguard` or `bash` first.

## Use locally

```sh
git clone --depth 1 -b main https://github.com/openwrt/openwrt
cd openwrt && ./scripts/feeds update -a && ./scripts/feeds install -a && cd ..

sh c526a-port/apply.sh main openwrt          # or: 2410
cat c526a-port/config/common.config \
    c526a-port/config/main.config > openwrt/.config

cd openwrt
make defconfig
make -j$(nproc)
```

Images land in `bin/targets/ipq40xx/generic/`:

- `*-hiwifi_c526a-squashfs-factory.ubi` — flash from the stock U-Boot web UI
- `*-hiwifi_c526a-squashfs-sysupgrade.bin` — flash from OpenWrt
- `*-hiwifi_c526a-128m-*` — 128M NAND unlock layout
- `*-initramfs-*` — runs from RAM, does not touch NAND

The workflow builds all four sources in parallel and uploads one artifact per
source.

## ADB host / SMS bridge

The router runs the ADB **host** (`adb`, not `adbd`) and can drive a phone
connected to the USB port. `package/c526a-adb` adds:

- `/etc/init.d/adb` — procd-managed `adb server`, bind address controlled by
  `adb.main.listen_lan` (default `127.0.0.1:5037`)
- `/etc/init.d/adbsms` + `/usr/bin/adb-sms` — polls new inbox rows from a
  **rooted** phone (`adb shell su` + `content query`), keeps the last
  `max_store` messages in `/tmp/adb-sms.json`, and can POST them to a webhook
  or a Telegram bot
- `/www/cgi-bin/adb-sms[?token=...]` — JSON endpoint
- `/usr/bin/adb-ctl` — `devices / connect / shell / sms / shot / tap / swipe /
  text / key / ui / install`

Config (`/etc/config/adb`):

```
config adb 'main'
	option enabled '1'
	option listen_lan '0'
	option connect ''          # e.g. '192.168.1.50:5555'

config sms 'main'
	option enabled '1'
	option interval '30'
	option max_store '50'
	option serial ''           # ANDROID_SERIAL for multi-device setups
	option webhook ''
	option telegram_token ''
	option telegram_chat ''
	option api_token ''
```

First use:

```sh
adb-ctl devices          # phone must have USB debugging enabled
adb-ctl sms              # requires root on the phone (Magisk su)
adb-ctl shot /tmp/a.png
adb-ctl tap 540 1200
```

`listen_lan=0` keeps port 5037 on localhost. Setting it to `1` exposes full
control of the phone to the whole LAN — only do that behind a firewall or
WireGuard. The CGI endpoint is unauthenticated unless `api_token` is set.

Image impact is small (a few hundred KB): this uses the `adb` package that
already exists in every supported tree.

## Known limitations / verify on hardware

1. **DSA port order.** swconfig ports 2/3/4 were LAN, 5 was WAN; the DTS maps
   them to `lan1/lan2/lan3`. Swap the `label` properties if reversed.
2. **MT7615E PCIe node.** Uses `wifi@1,0` / `reg = <0x00010000 ...>` (matches
   every other current ipq40xx port). If 2.4 GHz has no EEPROM data, check
   `dmesg | grep mt7615` and try `reg = <0x0 ...>`.
3. **NAND layout.** `hiwifi_c526a` keeps the stock 44M `ubi` partition;
   `hiwifi_c526a-128m` uses the whole 128M. Do not mix them up.
4. **Calibration.** The 24 KB `board-hiwifi_c526a.qca4019` blob is the only
   non-upstream firmware; it is installed as
   `/lib/firmware/ath10k/QCA4019/hw1.0/board-2.bin`.
5. **MAC addresses.** LAN MAC comes from the ASCII `Vfac_mac ` key in `bdinfo`
   (SPI-NOR); WAN is `+1`, radios are `+2` / `+3`.
6. **`mt7615_reboot`** unloads `mt7615e` before reboot; keep it unless proven
   unnecessary.

Nothing here has been runtime-tested on the hardware yet. The first build is
the syntax/wiring check, the first boot is the real test. Keep a working 5.4
image for recovery.
