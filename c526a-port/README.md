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
WireGuard, `ttyd` (web console), `adblock-fast`.

**Extra LuCI apps**
`luci-app-commands`, `luci-app-wifischedule`, `luci-app-hd-idle`,
`luci-app-adblock-fast`, plus Chinese translations for the ones that have
them.

**Tools / diagnostics**
`htop`, `curl`, `wget-ssl`, `nano`, `bash`, `usbutils`, `pciutils`,
`irqbalance`, `openssh-sftp-server`, `socat`, `tcpdump`, `ethtool`, and the
common USB-serial chips (`ch341`, `cp210x`, `ftdi`, `pl2303`).

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
- `/etc/init.d/adbnet` + `/usr/bin/adb-net` — keeps the network devices listed
  in `adb.main.connect` connected (reconnects after Wi-Fi drops / reboots)
- `/etc/init.d/adbsms` + `/usr/bin/adb-sms` — polls new inbox rows from a
  **rooted** phone (`adb shell su` + `content query`), keeps the last
  `max_store` messages in `/tmp/adb-sms.json`, and can POST them to a webhook
  or a Telegram bot
- `/www/cgi-bin/adb-sms[?token=...]` — JSON endpoint
- `/usr/bin/adb-ctl` — `devices / connect / tcpip / enable-tcp / shell / sms /
  shot / tap / swipe / text / key / ui / install`

Config (`/etc/config/adb`):

```
config adb 'main'
	option enabled '1'
	option listen_lan '0'
	option connect ''              # e.g. '192.168.1.50:5555'
	option reconnect '1'
	option reconnect_interval '30'

config sms 'main'
	option enabled '1'
	option interval '30'
	option max_store '50'
	option serial ''               # ANDROID_SERIAL for multi-device setups
	option webhook ''
	option telegram_token ''
	option telegram_chat ''
	option api_token ''
```

### Network ADB

USB is not required. Three ways to get a phone reachable over TCP:

1. **USB once** (works on every Android): connect the phone, authorise it, then
   `adb-ctl tcpip 5555`. Unplug and `adb-ctl connect 192.168.1.50:5555`.
2. **Rooted phone, no USB needed**: `adb-ctl enable-tcp 5555` sets
   `persist.adb.tcp.port`, so adbd listens on 5555 after every boot. Then
   `adb-ctl connect <ip>:5555`.
3. **Auto-connect**: put `192.168.1.50:5555` into `adb.main.connect`; the
   `adbnet` service reconnects every `reconnect_interval` seconds.

Android 11+ "Wireless debugging" needs `adb pair`, which adb 1.0.32 does not
implement — use option 1 or 2 above. Multiple phones are fine; set
`adb.sms.serial` to the one used for SMS.

First use:

```sh
adb-ctl devices          # USB or network, whichever is connected
adb-ctl sms              # requires root on the phone (Magisk su)
adb-ctl shot /tmp/a.png
adb-ctl tap 540 1200
```

`listen_lan=0` keeps port 5037 on localhost. Setting it to `1` exposes full
control of the phone to the whole LAN — only do that behind a firewall or
WireGuard.

### Web UI

```
http://<router>/adb/
```

A single-page Chinese UI on top of `/cgi-bin/adb-api`:

- 概览：ADB 服务状态、已连接设备
- 设备：列出设备、按 `ip:port` 网络连接、断开
- 短信：收件箱列表（来自 `adb-sms`），支持“立即轮询”
- 控制：截屏、点击/滑动/文本/按键、任意 `adb shell` 命令

API 例子（`token` 必须带上）：

```sh
TOKEN=$(adb-ctl token)
curl "http://192.168.1.29/cgi-bin/adb-api?action=status&token=$TOKEN"
curl "http://192.168.1.29/cgi-bin/adb-api?action=sms&token=$TOKEN"
curl "http://192.168.1.29/cgi-bin/adb-api?action=shell&cmd=id&token=$TOKEN"
```

- 首次启动会随机生成 token，写入 `/root/adb-token`（0600），也可用
  `adb-ctl token` 查看、`adb-ctl token <new>` 修改
- token 未设置时 API 不鉴权；设置后所有请求必须带 `token`
- 只适合 LAN 使用，**不要**把 80 端口暴露到 WAN
- 没有设备时截屏返回 HTTP 503，前端会提示失败

Image impact is small (a few hundred KB): this uses the `adb` package that
already exists in every supported tree.

## 多 WAN（四路上行）

`c526a-wan` 用 mwan3 管理四路上行，提供一个声明式配置和 `wanctl` 命令：

| uplink | 物理链路 | 说明 |
|---|---|---|
| `wan` | WAN 口 | DHCP / PPPoE / 静态，原有配置不动 |
| `wan2` | 指定网关 | **默认 `mode=port`：把 `lan3` 从网桥拿出来当第二个 WAN**；也支持 `mode=lan`（macvlan） |
| `wwan` | WiFi STA | travelmate 连接已有 WiFi，逻辑接口名 `wwan` |
| `usbwan` | USB | RNDIS/ECM/NCM 用 `proto dhcp`；4G 模块用 `qmi`/`mbim` |

### `mode=port` 已预配置好（牺牲 lan3）

出厂配置里 `wan2` 已经是：

```
option enabled '1'
option mode 'port'
option port 'lan3'
option proto 'dhcp'
```

刷机后 `wanctl` 会自动把 `lan3` 从 `br-lan` 摘出来，创建 `wan2`，加进
`wan` 防火墙区域和 mwan3。你只需要把网线插到 **LAN3 口**。

刷完先确认：

```sh
wanctl check                 # 检查配置/端口/地址
wanctl status                # 四路上行 + mwan3 状态
ip -br link show lan3        # 应显示 UP / LOWER_UP（插了网线）
ubus call network.interface.wan2 status
```

如果上游是静态地址：

```sh
wanctl wan2 port lan3 static 192.168.2.2 255.255.255.0 192.168.2.1
```

如果上游是 PPPoE：

```sh
wanctl set wan2 proto pppoe
wanctl set wan2 username 你的账号
wanctl set wan2 password 你的密码
```

回滚（把 lan3 还回 LAN 网桥）：

```sh
wanctl wan2 off
```

物理端口对应关系：DTS 里 `swport4 → lan3`，但 DSA 端口顺序还没有在真机上
确认过。如果插 LAN3 口 `ethtool lan3` 显示 no link、而别的口有 link，说明
顺序反了，把 `wan2.port` 改成实际有链路的那个口即可（`lan1`/`lan2`/`lan3`）。

### 其它上行和策略

```sh
# 指定网关（不想牺牲 LAN 口时用 macvlan）
wanctl wan2 lan
wanctl set wan2 ipaddr 192.168.1.2
wanctl set wan2 gateway 192.168.1.1

# WiFi STA（先用 travelmate 连上）
wanctl set wwan enabled 1

# USB
wanctl usb-detect
wanctl set usbwan enabled 1
wanctl set usbwan proto dhcp
wanctl set usbwan device usb0
# 4G 模块：wanctl set usbwan proto qmi / apn cmnet

# 策略
wanctl default failover      # 按 order 顺序故障切换（默认）
wanctl default balanced      # 按 weight 加权负载均衡
wanctl set wan2 weight 2

# 分流：指定目标走某一路
wanctl route add office via=wan2 dest_ip=192.168.1.0/24
wanctl route add nas via=wan dest_ip=10.0.0.0/8
wanctl route list
```

`wanctl apply` 会写入 `/etc/config/network`、把接口加进 `wan` 防火墙区域、
并整体生成 `/etc/config/mwan3`（globals/interface/member/policy/rule），
然后 reload network、restart mwan3。想先看会改什么可以用：

```sh
wanctl --dry-run apply
```

注意：

- `wanctl` 是 mwan3 配置的唯一来源，手改 LuCI 的 mwan3 页面会在下次
  `apply` 时被覆盖；策略请用 `wanctl route/default` 或直接改 `wanctl` 配置。
- `mode=port` 会占用一个 LAN 口（默认 `lan3`），关闭 wan2 时会自动还回网桥。
- 上游网段不要和本机 LAN 网段冲突（例如 LAN 是 `192.168.1.0/24`，wan2 静态
  地址就不要再给 `192.168.1.x`）。
- `mode=lan` 依赖 `kmod-macvlan`，上游交换机如果做了端口隔离可能不生效。
- mwan3 是**按连接**均衡，不是按包；单条大流量连接不会叠加带宽。
- 多路上行同时 `peerdns` 会让 `resolv.conf.auto` 抖动，`wwan`/`usbwan`
  建议固定 DNS 或 `peerdns 0`。
- 默认规则是 `failover`，`order` 决定优先级；`balanced` 用 `weight` 加权。

## Known limitations / verify on hardware

1. **DSA port order.** swconfig ports 2/3/4 were LAN, 5 was WAN; the DTS maps
   them to `lan1/lan2/lan3`. Swap the `label` properties if reversed.
2. **MT7615E PCIe node.** Uses `wifi@1,0` / `reg = <0x00010000 ...>` (matches
   every other current ipq40xx port). If 2.4 GHz has no EEPROM data, check
   `dmesg | grep mt7615` and try `reg = <0x0 ...>`.
3. **NAND layout.** `hiwifi_c526a` keeps the stock 44M `ubi` partition;
   `hiwifi_c526a-128m` uses the whole 128M. Do not mix them up.
4. **Calibration.** The 24 KB `board-hiwifi_c526a.qca4019` blob is the only
   non-upstream firmware. It is installed as
   `/lib/firmware/ath10k/QCA4019/hw1.0/board-hiwifi_c526a.bin` and copied to
   `board-2.bin` by `/lib/preinit/90_c526a_bdf` (after `mount_root`, before
   `kmodloader` probes ath10k). A direct install would clash with the file
   owned by `ath10k-board-qca4019`, which apk refuses to overwrite.
5. **MAC addresses.** LAN MAC comes from the ASCII `Vfac_mac ` key in `bdinfo`
   (SPI-NOR); WAN is `+1`, radios are `+2` / `+3`.
6. **`mt7615_reboot`** unloads `mt7615e` before reboot; keep it unless proven
   unnecessary.

Nothing here has been runtime-tested on the hardware yet. The first build is
the syntax/wiring check, the first boot is the real test. Keep a working 5.4
image for recovery.
