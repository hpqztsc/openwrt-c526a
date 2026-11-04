#
# C526A first-boot defaults: Chinese UI and timezone
#
include $(TOPDIR)/rules.mk

PKG_NAME:=c526a-defaults
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

# no upstream sources, only the files/ overlay
define Build/Compile
endef

define Package/c526a-defaults
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=C526A first-boot defaults (zh_CN, Asia/Shanghai)
  DEPENDS:=@TARGET_ipq40xx
endef

define Package/c526a-defaults/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/89-c526a-defaults $(1)/etc/uci-defaults/89-c526a-defaults
endef

$(eval $(call BuildPackage,c526a-defaults))
