#
# Multi-uplink manager for the HiWiFi C526A (mwan3 front-end)
#
include $(TOPDIR)/rules.mk

PKG_NAME:=c526a-wan
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

# no upstream sources, only the files/ overlay
define Build/Compile
endef

define Package/c526a-wan
  SECTION:=net
  CATEGORY:=Network
  TITLE:=C526A multi-uplink manager (wan/wan2/wwan/usbwan + mwan3)
  DEPENDS:=@TARGET_ipq40xx +mwan3 +luci-app-mwan3 +kmod-macvlan +jshn
endef

define Package/c526a-wan/description
  Declarative configuration for four uplinks (Ethernet WAN, a specified
  gateway, WiFi STA and USB tethering) with mwan3 failover, weighted load
  balancing and policy routes.  The "wanctl" command writes network,
  firewall and mwan3 configuration and reloads the services.
endef

define Package/c526a-wan/conffiles
/etc/config/wanctl
endef

define Package/c526a-wan/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/wanctl $(1)/etc/config/wanctl
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/wanctl $(1)/etc/init.d/wanctl
	$(INSTALL_DIR) $(1)/www/wan
	$(INSTALL_DATA) ./files/www/wan/index.html $(1)/www/wan/index.html
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) ./files/www/cgi-bin/wan-api $(1)/www/cgi-bin/wan-api
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/wanctl $(1)/usr/bin/wanctl
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/90-c526a-wan $(1)/etc/uci-defaults/90-c526a-wan
endef

$(eval $(call BuildPackage,c526a-wan))
