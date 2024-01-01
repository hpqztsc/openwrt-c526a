#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# 管理地址
sed -i 's/192.168.1.1/192.168.99.3/g' package/base-files/files/bin/config_generate

# 默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argonne/g' feeds/luci/collections/luci/Makefile

# 修改NAS为网络存储
sed -i 's/"NAS"/"网络存储"/g' `grep "NAS" -rl ./`

# 修改固件默认时区
sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate

# 修改固件默认名称
sed -i 's/ImmortalWrt/HIWIFI/g' package/base-files/files/bin/config_generate
