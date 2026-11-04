#
# ADB host service + SMS bridge for the HiWiFi C526A
#
# Depends on the vendored "adb" package (package/android-tools).
#
include $(TOPDIR)/rules.mk

PKG_NAME:=c526a-adb
PKG_RELEASE:=2

include $(INCLUDE_DIR)/package.mk

# no upstream sources, only the files/ overlay
define Build/Compile
endef

define Package/c526a-adb
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=ADB host + SMS bridge (HiWiFi C526A)
  DEPENDS:=@TARGET_ipq40xx +adb +curl +jshn +uhttpd +ttyd
endef

define Package/c526a-adb/description
  Runs the ADB server on the router, drives one or more USB/network Android
  devices (device-aware JSON API, web console, interactive terminal), polls
  new SMS per device (shell UID first, su as fallback), and optionally
  forwards them to a webhook or Telegram.
endef

define Package/c526a-adb/conffiles
/etc/config/adb
endef

define Package/c526a-adb/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/adb $(1)/etc/config/adb
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/adb $(1)/etc/init.d/adb
	$(INSTALL_BIN) ./files/etc/init.d/adbnet $(1)/etc/init.d/adbnet
	$(INSTALL_BIN) ./files/etc/init.d/adbsms $(1)/etc/init.d/adbsms
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/adb-net $(1)/usr/bin/adb-net
	$(INSTALL_BIN) ./files/usr/bin/adb-sms $(1)/usr/bin/adb-sms
	$(INSTALL_BIN) ./files/usr/bin/adb-ctl $(1)/usr/bin/adb-ctl
	$(INSTALL_BIN) ./files/usr/bin/adb-term $(1)/usr/bin/adb-term
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) ./files/www/cgi-bin/adb-sms $(1)/www/cgi-bin/adb-sms
	$(INSTALL_BIN) ./files/www/cgi-bin/adb-api $(1)/www/cgi-bin/adb-api
	$(INSTALL_DIR) $(1)/www/adb
	$(INSTALL_DATA) ./files/www/adb/index.html $(1)/www/adb/index.html
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/c526a-adb
	$(INSTALL_DATA) ./files/www/luci-static/resources/view/c526a-adb/overview.js $(1)/www/luci-static/resources/view/c526a-adb/overview.js
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./files/usr/share/luci/menu.d/luci-app-c526a-adb.json $(1)/usr/share/luci/menu.d/luci-app-c526a-adb.json
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/95-c526a-adb $(1)/etc/uci-defaults/95-c526a-adb
	$(INSTALL_BIN) ./files/etc/uci-defaults/96-c526a-adbterm $(1)/etc/uci-defaults/96-c526a-adbterm
endef

$(eval $(call BuildPackage,c526a-adb))
