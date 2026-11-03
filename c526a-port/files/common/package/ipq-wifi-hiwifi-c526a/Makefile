#
# ath10k board-2.bin override for the HiWiFi C526A
#
# The QCA4019 reference ("BDF") data for this board is not part of the
# upstream qca-wireless repository, so it is shipped here and installed
# over the generic board-2.bin from ath10k-firmware-qca4019-ct.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=ipq-wifi-hiwifi-c526a
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

# no upstream sources, only the board file in files/
define Build/Compile
endef

define Package/ipq-wifi-hiwifi-c526a
  SECTION:=firmware
  CATEGORY:=Firmware
  TITLE:=HiWiFi C526A ath10k board data
  DEPENDS:=@TARGET_ipq40xx
endef

define Package/ipq-wifi-hiwifi-c526a/description
  Board-specific ath10k board-2.bin for the HiWiFi C526A (IPQ4019).
endef

# The device definition removes the default ath10k-board-qca4019 package
# with "-ath10k-board-qca4019", so this file is the only owner of
# board-2.bin and apk/opkg do not complain about an overwrite.
define Package/ipq-wifi-hiwifi-c526a/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA4019/hw1.0
	$(INSTALL_DATA) ./files/board-hiwifi_c526a.qca4019 \
		$(1)/lib/firmware/ath10k/QCA4019/hw1.0/board-2.bin
endef

$(eval $(call BuildPackage,ipq-wifi-hiwifi-c526a))
