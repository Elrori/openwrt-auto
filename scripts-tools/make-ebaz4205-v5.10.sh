#!/bin/bash
CONFIG_FILE=zynq-ebaz4205-lite.config
DEVICE_NAME=zynq-ebaz4205
TARGET_NAME=zynq
CONFIG_TAGS='v21.02.3'
TOP_DIR=$PWD

echo "-------------------- Get openwrt source master --------------------"
if [ ! -d "openwrt" ]; then
  git clone --depth 1 -b $CONFIG_TAGS https://github.com/openwrt/openwrt.git
else
  echo "Pass"
fi
echo "Top dir: $TOP_DIR"
pushd openwrt
echo "Enter: $PWD"

echo "---------------------- Get kernel version -------------------------"
KERNEL_VERSION=$(cat target/linux/$TARGET_NAME/Makefile | grep KERNEL_PATCHVER | sed -r 's|.*([0-9]+.[0-9]+)$|\1|')
PATCHES=patches-$KERNEL_VERSION
if [ ! -e "include/kernel-$KERNEL_VERSION" ]; then
  VERSION_FILE=kernel-version.mk
else
  VERSION_FILE=kernel-$KERNEL_VERSION
fi
LINUX_VERSION=$(cat include/$VERSION_FILE | grep LINUX_VERSION-$KERNEL_VERSION | sed -r 's|.*(\.[0-9]+)$|\1|')
echo "KERNEL_VERSION=$KERNEL_VERSION$LINUX_VERSION"

echo "---------------------- Add EBAZ4205 patches -----------------------"
mkdir -p target/linux/zynq/$PATCHES
echo -e "bootargs=console=ttyPS0,115200n8 root=/dev/mmcblk0p2 rootwait earlyprintk \n\
bitstream_image=system.bit \n\
sdbootfit=echo Loading bitstream from SD/MMC/eMMC to RAM... && fatload mmc 0 0x3000000 \${bitstream_image} && fpga loadb 0 0x3000000 \${filesize} && echo Run uEnv.txt copying Linux from SD to RAM... && fatload mmc 0 0x1000000 fit.itb && echo Boot fit.itb from RAM && bootm 0x1000000 \n\
uenvcmd=run sdbootfit" > package/boot/uboot-zynq/files/uEnv-default.txt
cp $TOP_DIR/patches/ebaz4205-v4.14-u-boot-2018.07-19.07.3/022-v4.14-ebaz4205-support.patch target/linux/zynq/$PATCHES
cp $TOP_DIR/patches/ebaz4205-v4.14-u-boot-2018.07-19.07.3/026-u-boot-2018.07-ebaz4205-support.patch package/boot/uboot-zynq/patches
git apply $TOP_DIR/patches/ebaz4205-v4.14-u-boot-2018.07-19.07.3/openwrt-ebaz4205-19.07.3.patch
echo "Apply patches to target/linux/zynq/$PATCHES"

# echo "---------------------- Add luci-app-ssr-plus ----------------------"
# git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld
# svn checkout https://github.com/coolsnowwolf/lede/trunk/tools/ucl tools/ucl
# svn checkout https://github.com/coolsnowwolf/lede/trunk/tools/upx tools/upx
# for i in "dns2socks" "microsocks" "ipt2socks" "pdnsd-alt" "redsocks2"; do 
#   svn checkout "https://github.com/immortalwrt/packages/trunk/net/$i" "package/helloworld/$i"; 
# done
# sed -i '23a\tools-y += ucl upx' tools/Makefile # 使用sed插入特定行，在未来可能会出现问题
# sed -i '44a\$(curdir)/upx/compile := $(curdir)/ucl/compile' tools/Makefile

echo "---------------------- Add luci-app-openclash ----------------------"
rm -rf feeds/packages/libs/libcap
svn co https://github.com/openwrt/packages/branches/openwrt-21.02/libs/libcap/ feeds/packages/libs/libcap
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash package/luci-app-openclash
mkdir -p package/base-files/files/etc/openclash/core
wget -O clash.gz https://github.com/Dreamacro/clash/releases/download/v1.4.2/clash-linux-armv7-v1.4.2.gz 
wget -O clash_tun.gz https://github.com/vernesong/OpenClash/releases/download/TUN-Premium/clash-linux-armv7-2022.04.11.gz # for updates, go to: https://github.com/vernesong/OpenClash/releases/tag/TUN-Premium
wget -O clash_game.tar.gz https://github.com/vernesong/OpenClash/releases/download/TUN/clash-linux-armv7.tar.gz 
gunzip clash.gz && mv clash package/base-files/files/etc/openclash/core
gunzip clash_tun.gz && mv clash_tun package/base-files/files/etc/openclash/core
tar -zxvf clash_game.tar.gz && mv clash clash_game && mv clash_game package/base-files/files/etc/openclash/core
chmod +x package/base-files/files/etc/openclash/core/clash*


echo "---------------------- Get feeds ----------------------"
./scripts/feeds update -a
./scripts/feeds install -a

echo "--------------------- Add config-----------------------"
make menuconfig
#cp $TOP_DIR/config/$CONFIG_FILE .config

echo "-------------------- make download --------------------"
make defconfig
make download -j$(nproc)

echo "-------------------- make compile ---------------------"
make -j$(nproc) V=sc

echo "------------------- Pack artifacts --------------------"
mkdir artifacts
for file in bin/targets/*/*/*.gz; do
  bash -c "sha512sum $file | sed -r 's|([0-9a-z]+).*|\1|g' > $file.sha512sum"
  mv $file* artifacts/
done
svn checkout https://github.com/Elrori/EBAZ4205/trunk/archive/2018.3-1 fpga/
mv fpga/system667.bit fpga/system.bit 
mv fpga/system.bit artifacts

echo "----------------------- Finish ------------------------"
popd
#!/bin/bash
CONFIG_FILE=zynq-ebaz4205-lite.config
DEVICE_NAME=zynq-ebaz4205
TARGET_NAME=zynq
CONFIG_TAGS='v19.07.3'
TOP_DIR=$PWD

echo "-------------------- Get openwrt source master --------------------"
if [ ! -d "openwrt" ]; then
  git clone --depth 1 -b $CONFIG_TAGS https://github.com/openwrt/openwrt.git
else
  echo "Pass"
fi
echo "Top dir: $TOP_DIR"
pushd openwrt
echo "Enter: $PWD"

echo "---------------------- Get kernel version -------------------------"
KERNEL_VERSION=$(cat target/linux/$TARGET_NAME/Makefile | grep KERNEL_PATCHVER | sed -r 's|.*([0-9]+.[0-9]+)$|\1|')
PATCHES=patches-$KERNEL_VERSION
if [ ! -e "include/kernel-$KERNEL_VERSION" ]; then
  VERSION_FILE=kernel-version.mk
else
  VERSION_FILE=kernel-$KERNEL_VERSION
fi
LINUX_VERSION=$(cat include/$VERSION_FILE | grep LINUX_VERSION-$KERNEL_VERSION | sed -r 's|.*(\.[0-9]+)$|\1|')
echo "KERNEL_VERSION=$KERNEL_VERSION$LINUX_VERSION"

echo "---------------------- Add EBAZ4205 patches -----------------------"
mkdir -p target/linux/zynq/$PATCHES
echo -e "bootargs=console=ttyPS0,115200n8 root=/dev/mmcblk0p2 rootwait earlyprintk \n\
bitstream_image=system.bit \n\
sdbootfit=echo Loading bitstream from SD/MMC/eMMC to RAM... && fatload mmc 0 0x3000000 \${bitstream_image} && fpga loadb 0 0x3000000 \${filesize} && echo Run uEnv.txt copying Linux from SD to RAM... && fatload mmc 0 0x1000000 fit.itb && echo Boot fit.itb from RAM && bootm 0x1000000 \n\
uenvcmd=run sdbootfit" > package/boot/uboot-zynq/files/uEnv-default.txt
cp openwrt-auto/patches/ebaz4205-v5.10-u-boot-2019.07/020-v5.10-ebaz4205-support.patch target/linux/zynq/${{ env.PATCHES_FILE }}/
cp openwrt-auto/patches/ebaz4205-v5.10-u-boot-2019.07/111-u-boot-2019.07-ebaz4205-support.patch package/boot/uboot-zynq/patches/
git apply openwrt-auto/patches/ebaz4205-v5.10-u-boot-2019.07/openwrt-ebaz4205.patch
echo "Apply patches to target/linux/zynq/$PATCHES"

# echo "---------------------- Add luci-app-ssr-plus ----------------------"
# git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld
# svn checkout https://github.com/coolsnowwolf/lede/trunk/tools/ucl tools/ucl
# svn checkout https://github.com/coolsnowwolf/lede/trunk/tools/upx tools/upx
# for i in "dns2socks" "microsocks" "ipt2socks" "pdnsd-alt" "redsocks2"; do 
#   svn checkout "https://github.com/immortalwrt/packages/trunk/net/$i" "package/helloworld/$i"; 
# done
# sed -i '23a\tools-y += ucl upx' tools/Makefile # 使用sed插入特定行，在未来可能会出现问题
# sed -i '44a\$(curdir)/upx/compile := $(curdir)/ucl/compile' tools/Makefile

echo "---------------------- Add luci-app-openclash ----------------------"
rm -rf feeds/packages/libs/libcap
svn co https://github.com/openwrt/packages/branches/openwrt-21.02/libs/libcap/ feeds/packages/libs/libcap
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash package/luci-app-openclash
mkdir -p package/base-files/files/etc/openclash/core
wget -O clash.gz https://github.com/Dreamacro/clash/releases/download/v1.4.2/clash-linux-armv7-v1.4.2.gz 
wget -O clash_tun.gz https://github.com/vernesong/OpenClash/releases/download/TUN-Premium/clash-linux-armv7-2022.04.11.gz # for updates, go to: https://github.com/vernesong/OpenClash/releases/tag/TUN-Premium
wget -O clash_game.tar.gz https://github.com/vernesong/OpenClash/releases/download/TUN/clash-linux-armv7.tar.gz 
gunzip clash.gz && mv clash package/base-files/files/etc/openclash/core
gunzip clash_tun.gz && mv clash_tun package/base-files/files/etc/openclash/core
tar -zxvf clash_game.tar.gz && mv clash clash_game && mv clash_game package/base-files/files/etc/openclash/core
chmod +x package/base-files/files/etc/openclash/core/clash*


echo "---------------------- Get feeds ----------------------"
./scripts/feeds update -a
./scripts/feeds install -a

echo "--------------------- Add config-----------------------"
make menuconfig
#cp $TOP_DIR/config/$CONFIG_FILE .config

echo "-------------------- make download --------------------"
make defconfig
make download -j$(nproc)

echo "-------------------- make compile ---------------------"
make -j$(nproc) V=sc

echo "------------------- Pack artifacts --------------------"
mkdir artifacts
for file in bin/targets/*/*/*.gz; do
  bash -c "sha512sum $file | sed -r 's|([0-9a-z]+).*|\1|g' > $file.sha512sum"
  mv $file* artifacts/
done
svn checkout https://github.com/Elrori/EBAZ4205/trunk/archive/2018.3-1 fpga/
mv fpga/system667.bit fpga/system.bit 
mv fpga/system.bit artifacts

echo "----------------------- Finish ------------------------"
popd
