#
# Site-specific defaults for this C526A (management address / SSH keys)
#
include $(TOPDIR)/rules.mk

PKG_NAME:=c526a-site
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

# no upstream sources, only files/
define Build/Compile
endef

define Package/c526a-site
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=C526A site defaults (LAN 192.168.1.29, key-only SSH)
  DEPENDS:=@TARGET_ipq40xx
endef

define Package/c526a-site/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/89-c526a-site $(1)/etc/uci-defaults/89-c526a-site
	$(INSTALL_DIR) $(1)/etc/dropbear
	$(INSTALL_DATA) ./files/etc/dropbear/authorized_keys $(1)/etc/dropbear/authorized_keys
endef

$(eval $(call BuildPackage,c526a-site))
