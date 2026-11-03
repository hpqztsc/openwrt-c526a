#
# ADB host service + SMS bridge for the HiWiFi C526A
#
# Depends on the vendored "adb" package (package/android-tools).
#
include $(TOPDIR)/rules.mk

PKG_NAME:=c526a-adb
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

# no upstream sources, only the files/ overlay
define Build/Compile
endef

define Package/c526a-adb
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=ADB host + SMS bridge (HiWiFi C526A)
  DEPENDS:=@TARGET_ipq40xx +adb +curl +jshn +uhttpd
endef

define Package/c526a-adb/description
  Runs the ADB server on the router, polls new SMS from a rooted Android
  device over ADB, optionally forwards them to a webhook or Telegram, and
  exposes the inbox as JSON at /cgi-bin/adb-sms.
endef

define Package/c526a-adb/conffiles
/etc/config/adb
endef

define Package/c526a-adb/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/adb $(1)/etc/config/adb
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/adb $(1)/etc/init.d/adb
	$(INSTALL_BIN) ./files/etc/init.d/adbsms $(1)/etc/init.d/adbsms
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/adb-sms $(1)/usr/bin/adb-sms
	$(INSTALL_BIN) ./files/usr/bin/adb-ctl $(1)/usr/bin/adb-ctl
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) ./files/www/cgi-bin/adb-sms $(1)/www/cgi-bin/adb-sms
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/95-c526a-adb $(1)/etc/uci-defaults/95-c526a-adb
endef

$(eval $(call BuildPackage,c526a-adb))
