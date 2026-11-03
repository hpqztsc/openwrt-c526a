# HiWiFi C526A (极路由 X) support for current OpenWrt main

This is a board-support port of the HiWiFi C526A (IPQ4019 + MT7615E) to the
current `openwrt/openwrt` tree, which runs kernel 6.18 with DSA.

It is **not** a driver port: `ath10k`, `mt7615e`, the QCA ESS switch, the
QLogic NAND controller, `dwc3` and the PCIe host are all upstream. What is
added here is the per-board data:

- device tree (`target/linux/ipq40xx/dts/qcom-ipq4019-c526a*.dts*`)
- image definition (`hiwifi_c526a` / `hiwifi_c526a-128m`)
- QCA4019 board file (`package/ipq-wifi-hiwifi-c526a`)
- network / MAC / sysupgrade glue

The board files were taken from `padavanonly/immortalwrt` (kernel 5.4) and
rewritten for 6.18 / DSA:

- `swconfig` switch config -> DSA `&switch` + `&swport2..5` labels
- `qcom,ath10k-calibration-variant` -> `qcom,calibration-variant`
- `ess-switch@c000000` / `edma@c080000` -> `&switch` / `&gmac`
- `ess-psgmii@98000` dropped (now part of the switch node)
- NAND pinctrl added, `&pcie_bridge0` used for the MT7615E node

## Layout

```
apply.sh                     apply everything to a clean tree
patches/0001-*.patch         edits to existing upstream files
files/                       new files, copied over the tree
config/c526a.config          minimal seed config for `make defconfig`
```

## Use

```sh
git clone --depth 1 -b main https://github.com/openwrt/openwrt
./apply.sh openwrt
cp config/c526a.config openwrt/.config
cd openwrt
make defconfig
make -j$(nproc)
```

Images end up in `bin/targets/ipq40xx/generic/`:

- `*-hiwifi_c526a-squashfs-factory.ubi` - flash from the stock U-Boot web UI
- `*-hiwifi_c526a-squashfs-sysupgrade.bin` - flash from OpenWrt
- `*-hiwifi_c526a-128m-*` - same, for the 128M NAND unlock layout
- `*-initramfs-*` - RAM-only image, useful for testing without writing NAND

The `.github/workflows/build-c526a-main.yml` workflow does all of this on
GitHub Actions and publishes the images as a release.

## Known limitations / must verify on hardware

1. **DSA port order.** The stock firmware used swconfig ports 2/3/4 for LAN
   and 5 for WAN; the DTS maps them to `lan1/lan2/lan3` in that order. If the
   jacks come out reversed, just swap the `label` properties.
2. **MT7615E PCIe node.** The original QSDK tree used `wifi@1,0` with
   `reg = <0x0 ...>`, which is preserved here. If 2.4 GHz comes up without
   EEPROM data (`dmesg | grep mt7615`), try `reg = <0x00010000 0 0 0 0>`.
3. **NAND layout.** `hiwifi_c526a` keeps the stock 44M `ubi` partition,
   `hiwifi_c526a-128m` uses the whole 128M. Flashing the wrong one is not
   destructive to the bootloader, but the rootfs will be the wrong size.
4. **Atheros calibration.** The 24 KB `board-hiwifi_c526a.qca4019` file is
   the only non-upstream blob. It is installed as
   `/lib/firmware/ath10k/QCA4019/hw1.0/board-2.bin`, same mechanism as the
   upstream `ipq-wifi-*` packages.
5. **MAC addresses.** LAN MAC is read from the ASCII key `Vfac_mac ` in the
   `bdinfo` SPI-NOR partition; WAN is `+1`, radios are `+2` / `+3`.
6. **`mt7615_reboot`** unloads `mt7615e` before reboot. It was needed with the
   old driver; keep it unless you prove it is unnecessary.

None of this has been runtime-tested on the device yet - the first build is
the syntax/wiring check, the first boot is the real test. Keep a working 5.4
image around for recovery.
