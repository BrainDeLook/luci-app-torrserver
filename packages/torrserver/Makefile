include $(TOPDIR)/rules.mk

PKG_NAME:=torrserver
PKG_VERSION:=147
PKG_RELEASE:=1
PKG_LICENSE:=GPL-3.0-only
PKG_MAINTAINER:=BrainDeLook
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/torrserver
  SECTION:=net
  CATEGORY:=Network
  TITLE:=TorrServer torrent streaming server
  URL:=https://github.com/BrainDeLook/luci-app-torrserver
  DEPENDS:=+ca-bundle +procd +uci +jshn
  CONFLICTS:=torrserver-upx torrserver-official
endef

define Package/torrserver/description
  TorrServer MatriX.$(PKG_VERSION), built from official upstream sources.
  Includes a native procd service and UCI configuration for OpenWrt.
endef

define Package/torrserver/conffiles
/etc/config/torrserver
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	test -s "$(TORRSERVER_BINARY)"
	$(CP) "$(TORRSERVER_BINARY)" $(PKG_BUILD_DIR)/torrserver
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/torrserver/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/share/torrserver $(1)/etc/init.d $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/torrserver $(1)/usr/bin/torrserver
	$(INSTALL_BIN) ./files/torrserver.init $(1)/etc/init.d/torrserver
	$(INSTALL_CONF) ./files/torrserver.config $(1)/etc/config/torrserver
	printf 'MatriX.$(PKG_VERSION)-r$(PKG_RELEASE)\n' > $(1)/usr/share/torrserver/version
endef

define Package/torrserver/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0
chmod 600 /etc/config/torrserver
/etc/init.d/torrserver enable
/etc/init.d/torrserver restart
endef

define Package/torrserver/prerm
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0
/etc/init.d/torrserver stop
endef

$(eval $(call BuildPackage,torrserver))
