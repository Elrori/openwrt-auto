#!/bin/bash
CONFIG_FILE=zynq-zed-lite.config
DEVICE_NAME=zynq-ebaz4205
TARGET_NAME=zynq

# Get openwrt source master
echo "-----------> Get openwrt source master"
if [ ! -d "openwrt" ]; then
  git clone https://github.com/openwrt/openwrt.git
fi

cd openwrt

# Get kernel version
echo "-----------> Get kernel version"
KERNEL_VERSION=$(cat target/linux/$TARGET_NAME/Makefile | grep KERNEL_PATCHVER | sed -r 's|.*([0-9]+.[0-9]+)$|\1|')
LINUX_VERSION=$(cat include/kernel-$KERNEL_VERSION | grep LINUX_VERSION-$KERNEL_VERSION | sed -r 's|.*(\.[0-9]+)$|\1|')
echo "KERNEL_VERSION=$KERNEL_VERSION$LINUX_VERSION"

# Add luci-app-ssr-plus
echo "-----------> Add luci-app-ssr-plus"
git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld
svn checkout https://github.com/coolsnowwolf/lede/trunk/tools/ucl tools/ucl
svn checkout https://github.com/coolsnowwolf/lede/trunk/tools/upx tools/upx
for i in "dns2socks" "microsocks" "ipt2socks" "pdnsd-alt" "redsocks2"; do 
svn checkout "https://github.com/immortalwrt/packages/trunk/net/$i" "package/helloworld/$i"; 
done
sed -i '23a\tools-y += ucl upx' tools/Makefile # 使用sed插入特定行，在未来可能会出现问题
sed -i '41a\$(curdir)/upx/compile := $(curdir)/ucl/compile' tools/Makefile
./scripts/feeds update -a
./scripts/feeds install -a

# Add config from https://github.com/Elrori/openwrt-auto.git
echo "-----------> Add config from https://github.com/Elrori/openwrt-auto.git"
git clone https://github.com/Elrori/openwrt-auto.git
cp openwrt-auto/config/$CONFIG_FILE .config

# make download
echo "-----------> make download"
make defconfig
make download -j$(nproc)

# make compile
echo "-----------> make compile"
make -j$(nproc) V=sc

# make image from zed board
echo "-----------> make image from zed board"
mkdir artifacts
svn checkout https://github.com/Elrori/EBAZ4205/trunk/archive/2018.3-1 artifacts/fpga
cp artifacts/fpga/zynq-ebaz4205.dts build_dir/target-*/linux-zynq/linux-$KERNEL_VERSION/arch/arm/boot/dts/zynq-zed.dts
make -j$(nproc) V=sc

echo "-----------> 重新编译成功,开始制作ebaz4205镜像"
echo -e "bootargs=console=ttyPS0,115200n8 root=/dev/mmcblk0p2 rootwait earlyprintk \n\
uenvcmd=run sdbootfit \n\
sdbootfit=echo Run uEnv.txt copying Linux from SD to RAM... && \n\
fatload mmc 0 0x1000000 fit.itb && \n\
echo Boot fit.itb from RAM && \n\
bootm 0x1000000;" > artifacts/uEnv.txt
cp build_dir/target-*/linux-zynq/Image artifacts/
cp build_dir/target-*/linux-zynq/linux-$KERNEL_VERSION/arch/arm/boot/dts/zynq-zed.dtb artifacts/zynq-ebaz4205.dtb
cp build_dir/target-*/linux-zynq/root.ext4 artifacts/
gzip -f -9n -c artifacts/Image > artifacts/Image.gz
scripts/mkits.sh -D ebang_zynq-ebaz4205 -o $(pwd)/artifacts/fit.its -k $(pwd)/artifacts/Image.gz -C gzip   -d $(pwd)/artifacts/zynq-ebaz4205.dtb   -a 0x8000 -e 0x8000    -c "config-1" -A arm -v $KERNEL_VERSION
staging_dir/host/bin/mkimage -f $(pwd)/artifacts/fit.its $(pwd)/artifacts/fit.itb
staging_dir/host/bin/mkfs.fat $(pwd)/artifacts/boot -C 16384
staging_dir/host/bin/mcopy -i $(pwd)/artifacts/boot $(pwd)/artifacts/fpga/BOOT.bin ::boot.bin
staging_dir/host/bin/mcopy -i $(pwd)/artifacts/boot $(pwd)/artifacts/uEnv.txt ::uEnv.txt
staging_dir/host/bin/mcopy -i $(pwd)/artifacts/boot $(pwd)/artifacts/fit.itb ::fit.itb
export PATH=$PATH:staging_dir/host/bin
target/linux/zynq/image/gen_zynq_sdcard_img.sh $(pwd)/artifacts/openwrt-zynq-ebang_zynq-ebaz4205-ext4-sdcard-precompileduboot.img.gz $(pwd)/artifacts/boot $(pwd)/artifacts/root.ext4 16 512
gzip -f -9n -c artifacts/openwrt-zynq-ebang_zynq-ebaz4205-ext4-sdcard-precompileduboot.img.gz > artifacts/openwrt-zynq-ebang_zynq-ebaz4205-ext4-sdcard-precompileduboot.img.gz.new
rm -rf artifacts/openwrt-zynq-ebang_zynq-ebaz4205-ext4-sdcard-precompileduboot.img.gz
mv artifacts/openwrt-zynq-ebang_zynq-ebaz4205-ext4-sdcard-precompileduboot.img.gz.new artifacts/openwrt-zynq-ebang_zynq-ebaz4205-ext4-sdcard-precompileduboot.img.gz
rm -rf artifacts/Image artifacts/boot artifacts/fit.its artifacts/fpga artifacts/root.ext4

echo "-----------> SUCCESS"