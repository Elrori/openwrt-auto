cp openwrt-auto/patches/ebaz4205-v5.10-u-boot-2019.07/020-v5.10-ebaz4205-support.patch target/linux/zynq/${{ env.PATCHES_FILE }}/
cp openwrt-auto/patches/ebaz4205-v5.10-u-boot-2019.07/111-u-boot-2019.07-ebaz4205-support.patch package/boot/uboot-zynq/patches/
git apply openwrt-auto/patches/ebaz4205-v5.10-u-boot-2019.07/openwrt-ebaz4205.patch
