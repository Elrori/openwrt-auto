#!/bin/bash
CONFIG_FILE=zynq-ebaz4205-lite.config
DEVICE_NAME=zynq-ebaz4205
TARGET_NAME=zynq
CONFIG_TAGS='v19.07.3' # v19.07 was a stable version for ebaz4205, modifications are not recommended
TOP_DIR=$PWD

echo "----------------------> Get openwrt source master"
if [ ! -d "openwrt" ]; then
  git clone --depth 1 -b $CONFIG_TAGS https://github.com/openwrt/openwrt.git
else
  echo "Pass"
fi
echo "Top dir: $TOP_DIR"
pushd openwrt
echo "Enter: $PWD"


echo "----------------------> Get kernel version"
KERNEL_VERSION=$(cat target/linux/$TARGET_NAME/Makefile | grep KERNEL_PATCHVER | sed -r 's|.*([0-9]+.[0-9]+)$|\1|')
PATCHES=patches-$KERNEL_VERSION
if [ ! -e "include/kernel-$KERNEL_VERSION" ]; then
  VERSION_FILE=kernel-version.mk
else
  VERSION_FILE=kernel-$KERNEL_VERSION
fi
LINUX_VERSION=$(cat include/$VERSION_FILE | grep LINUX_VERSION-$KERNEL_VERSION | sed -r 's|.*(\.[0-9]+)$|\1|')
echo "KERNEL_VERSION=$KERNEL_VERSION$LINUX_VERSION"


#echo "----------------------> Add EBAZ4205 patches"
#mkdir -p target/linux/zynq/$PATCHES
#cp $TOP_DIR/patches/ebaz4205-v4.14-u-boot-2018.07-19.07.3/022-v4.14-ebaz4205-support.patch target/linux/zynq/$PATCHES
#cp $TOP_DIR/patches/ebaz4205-v4.14-u-boot-2018.07-19.07.3/111-u-boot-2018.07-ebaz4205-support.patch package/boot/uboot-zynq/patches
#git apply $TOP_DIR/patches/ebaz4205-v4.14-u-boot-2018.07-19.07.3/openwrt-ebaz4205-19.07.3.patch
#echo "Apply patches to target/linux/zynq/$PATCHES!"




#echo "----------------------> Add luci-app-ssr-plus"
#git clone --depth=1 https://github.com/fw876/helloworld.git package/helloworld
#svn checkout https://github.com/coolsnowwolf/lede/trunk/tools/ucl tools/ucl
#svn checkout https://github.com/coolsnowwolf/lede/trunk/tools/upx tools/upx
#for i in "dns2socks" "microsocks" "ipt2socks" "pdnsd-alt" "redsocks2"; do 
#  svn checkout "https://github.com/immortalwrt/packages/trunk/net/$i" "package/helloworld/$i"; 
#done
#sed -i '23a\tools-y += ucl upx' tools/Makefile # 使用sed插入特定行，在未来可能会出现问题
#sed -i '41a\$(curdir)/upx/compile := $(curdir)/ucl/compile' tools/Makefile




echo "----------------------> Get feeds"
./scripts/feeds update -a
./scripts/feeds install -a


echo "----------------------> Add config from elrori/openwrt-auto"
make menuconfig
#cp $TOP_DIR/config/$CONFIG_FILE .config


echo "----------------------> make download"
make defconfig
make download -j$(nproc)


echo "----------------------> make compile"
make -j$(nproc) V=sc


echo "----------------------> Pack artifacts"
mkdir artifacts
for file in bin/targets/*/*/*.gz; do
  sudo bash -c "sha512sum $file | sed -r 's|([0-9a-z]+).*|\1|g' > $file.sha512sum"
  sudo mv $file* artifacts/
done

echo "----------------------> Finish"
popd