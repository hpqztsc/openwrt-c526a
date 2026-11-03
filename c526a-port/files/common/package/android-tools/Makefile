#
# OpenWrt package recipe for android-tools (adb / fastboot).
# Source: nmeum/android-tools — Linux port used by Alpine, Arch, Gentoo.
#
# Builds the Android Debug Bridge (`adb`) client/server for talking to
# Quectel modems exposing an ADB endpoint after USB-composition switch.
# Fastboot is included from the same source tree at no extra build cost.
#
# Refs:
#   https://github.com/nmeum/android-tools
#   https://github.com/vjt/openwrt-android-tools
#

include $(TOPDIR)/rules.mk

PKG_NAME:=android-tools
PKG_VERSION:=35.0.2
PKG_RELEASE:=2

# Use the upstream release tarball (carries vendored & patched copies of
# BoringSSL, fmt, libusb, etc.) instead of a raw git clone — saves us from
# having to package boringssl etc. as separate OpenWrt packages.
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=https://github.com/nmeum/android-tools/releases/download/$(PKG_VERSION)
PKG_HASH:=d2c3222280315f36d8bfa5c02d7632b47e365bfe2e77e99a3564fb6576f04097
PKG_MIRROR_HASH:=skip

PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Marcello Barnaba <vjt@openssl.it>

PKG_BUILD_DEPENDS:=protobuf/host
PKG_BUILD_PARALLEL:=1

CMAKE_INSTALL:=1
# Force out-of-source build: upstream's CMakeLists.mkbootimg.txt creates
# a symlink under ${CMAKE_CURRENT_BINARY_DIR}/mkbootimg and then
# install(FILES …) on it, which collides with the same-named source
# subdir if the build dir == source dir (default OpenWrt cmake.mk).
CMAKE_BINARY_SUBDIR:=build

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/android-tools/Default
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Android platform tools
  URL:=https://github.com/nmeum/android-tools
  DEPENDS:=+libstdcpp +libusb-1.0 +libpcre2 +zlib \
           +protobuf +abseil-cpp +libfmt +liblz4 +libzstd \
           +libbrotlicommon +libbrotlidec +libbrotlienc
endef

define Package/adb
  $(call Package/android-tools/Default)
  TITLE:=Android Debug Bridge client
endef

define Package/adb/description
  Android Debug Bridge: command-line tool that lets you communicate
  with an Android-compatible device. Used here to talk to the Quectel
  RM520N-GL modem ADB endpoint after the USB-composition switch.
endef

define Package/fastboot
  $(call Package/android-tools/Default)
  TITLE:=Android fastboot client
endef

define Package/fastboot/description
  Fastboot: command-line tool to flash images to bootloader-mode
  Android-compatible devices.
endef

CMAKE_OPTIONS += \
	-DBUILD_TESTING=OFF \
	-DANDROID_TOOLS_USE_BUNDLED_FMT=OFF \
	-DANDROID_TOOLS_USE_BUNDLED_LIBUSB=OFF \
	-DANDROID_TOOLS_LIBUSB_ENABLE_UDEV=OFF \
	-DProtobuf_PROTOC_EXECUTABLE=$(STAGING_DIR_HOSTPKG)/bin/protoc

# libziparchive's public header `zip_writer.h` includes <gtest/gtest_prod.h>
# even when tests are off (FRIEND_TEST macro). The release tarball already
# carries a vendored googletest under boringssl/third_party — point CFLAGS
# at it so the header resolves without forcing a system gtest dependency.
TARGET_CFLAGS += -I$(PKG_BUILD_DIR)/vendor/boringssl/third_party/googletest/googletest/include
TARGET_CXXFLAGS += -I$(PKG_BUILD_DIR)/vendor/boringssl/third_party/googletest/googletest/include

# Cross-compile fix: ProtobufConfig.cmake (in target staging) sets the
# imported `protobuf::protoc` target's IMPORTED_LOCATION to the target's
# musl-linked protoc-3.17.3.0 binary, which can't run on the build host.
# Overwrite that path with the host (glibc/build-arch) protoc so ninja's
# CUSTOM_COMMAND for proto codegen actually executes during cross build.
#
# PKG_BUILD_DEPENDS:=protobuf/host doesn't reliably auto-trigger the
# host build in SDK mode (fresh SDK, no prior cache), so force it here
# via recursive make before copying. Idempotent if already built.
PROTOBUF_HOST_DIR := $(if $(wildcard $(TOPDIR)/package/feeds/packages/protobuf),package/feeds/packages/protobuf,package/protobuf)

define Build/Configure
	+$(MAKE) -C $(TOPDIR) $(PROTOBUF_HOST_DIR)/host/compile V=s
	[ ! -x $(STAGING_DIR_HOSTPKG)/bin/protoc ] || \
		cp -f $(STAGING_DIR_HOSTPKG)/bin/protoc \
			$(STAGING_DIR)/usr/bin/protoc-3.17.3.0 || true
	$(call Build/Configure/Default)
endef

define Package/adb/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/adb $(1)/usr/bin/adb
endef

define Package/fastboot/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/fastboot $(1)/usr/bin/fastboot
endef

$(eval $(call BuildPackage,adb))
$(eval $(call BuildPackage,fastboot))
