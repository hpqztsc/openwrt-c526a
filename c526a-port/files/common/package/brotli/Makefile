#
# OpenWrt package recipe for Google Brotli compression library.
#
# Required by android-tools (>= 34.x) which links libbrotli{common,dec,enc}
# via pkg-config. Not present in the OpenWrt 25.12 packages feed, so it
# rides alongside android-tools in this repo.
#
# Refs:
#   https://github.com/google/brotli
#   https://www.ietf.org/archive/id/draft-alakuijala-brotli-08.txt
#

include $(TOPDIR)/rules.mk

PKG_NAME:=brotli
PKG_VERSION:=1.1.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/google/brotli.git
PKG_SOURCE_VERSION:=ed738e842d2fbdf2d6459e39267a633c4a9b2f5d
PKG_SOURCE_DATE:=2023-09-21
PKG_MIRROR_HASH:=skip

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Marcello Barnaba <vjt@openssl.it>

PKG_BUILD_PARALLEL:=1
CMAKE_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/brotli/Default
  SECTION:=libs
  CATEGORY:=Libraries
  URL:=https://github.com/google/brotli
endef

define Package/libbrotli
  $(call Package/brotli/Default)
  TITLE:=Brotli generic compression library
  DEPENDS:=+libbrotlicommon +libbrotlidec +libbrotlienc
endef

define Package/libbrotli/description
  Meta-package pulling in Brotli common, decoder and encoder shared libs.
endef

define Package/libbrotlicommon
  $(call Package/brotli/Default)
  TITLE:=Brotli common runtime library
endef

define Package/libbrotlidec
  $(call Package/brotli/Default)
  TITLE:=Brotli decoder library
  DEPENDS:=+libbrotlicommon
endef

define Package/libbrotlienc
  $(call Package/brotli/Default)
  TITLE:=Brotli encoder library
  DEPENDS:=+libbrotlicommon
endef

define Package/brotli
  $(call Package/brotli/Default)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Brotli compression CLI
  DEPENDS:=+libbrotlidec +libbrotlienc
endef

CMAKE_OPTIONS += \
	-DBROTLI_DISABLE_TESTS=ON \
	-DBROTLI_BUNDLED_MODE=OFF \
	-DBROTLI_EMSCRIPTEN=OFF \
	-DBUILD_SHARED_LIBS=ON

define Package/libbrotlicommon/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libbrotlicommon.so* $(1)/usr/lib/
endef

define Package/libbrotlidec/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libbrotlidec.so* $(1)/usr/lib/
endef

define Package/libbrotlienc/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libbrotlienc.so* $(1)/usr/lib/
endef

define Package/libbrotli/install
	# Meta-package, nothing to install
	$(INSTALL_DIR) $(1)/usr/lib
endef

define Package/brotli/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/brotli $(1)/usr/bin/brotli
endef

$(eval $(call BuildPackage,libbrotlicommon))
$(eval $(call BuildPackage,libbrotlidec))
$(eval $(call BuildPackage,libbrotlienc))
$(eval $(call BuildPackage,libbrotli))
$(eval $(call BuildPackage,brotli))
