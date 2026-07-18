MILKV_BOOT_BLOBS_VERSION = 1.1.4
MILKV_BOOT_BLOBS_SITE = $(BR2_EXTERNAL_MILKV_PATH)/package/milkv-boot-blobs
MILKV_BOOT_BLOBS_SITE_METHOD = local

define HOST_MILKV_BOOT_BLOBS_INSTALL_CMDS
	$(INSTALL) -d $(HOST_DIR)/share/firmware/milkv/
	cp -a $(@D)/blobs/* $(HOST_DIR)/share/firmware/milkv/
endef

$(eval $(host-generic-package))
