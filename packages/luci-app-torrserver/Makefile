include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-torrserver
PKG_VERSION:=3.0.0
PKG_RELEASE:=1
PKG_MAINTAINER:=BrainDeLook

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-torrserver
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI interface for TorrServer
  URL:=https://github.com/BrainDeLook/luci-app-torrserver
  DEPENDS:=+luci-base +rpcd +rpcd-mod-luci +jshn +jsonfilter +torrserver
  PKGARCH:=all
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-torrserver/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/torrserver
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d $(1)/usr/share/rpcd/acl.d $(1)/usr/libexec/rpcd
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(LUCI_LMO) $(1)/usr/lib/lua/luci/i18n/torrserver.ru.lmo
	$(INSTALL_DATA) $(LUCI_SOURCE_DIR)/view/torrserver/overview.js $(1)/www/luci-static/resources/view/torrserver/overview.js
	$(INSTALL_DATA) $(LUCI_SOURCE_DIR)/menu.d/luci-app-torrserver.json $(1)/usr/share/luci/menu.d/luci-app-torrserver.json
	$(INSTALL_DATA) $(LUCI_SOURCE_DIR)/acl.d/luci-app-torrserver.json $(1)/usr/share/rpcd/acl.d/luci-app-torrserver.json
	$(INSTALL_BIN) $(LUCI_SOURCE_DIR)/rpcd/luci.torrserver $(1)/usr/libexec/rpcd/luci.torrserver
endef

define Package/luci-app-torrserver/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0
rm -f /tmp/luci-indexcache
/etc/init.d/rpcd restart
endef

$(eval $(call BuildPackage,luci-app-torrserver))
