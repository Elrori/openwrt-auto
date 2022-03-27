#!/bin/bash
mkdir artifacts
rm -rf artifacts/*
svn checkout https://github.com/Elrori/EBAZ4205/trunk/archive/2018.3-1 artifacts/fpga
echo -e "bootargs=console=ttyPS0,115200n8 root=/dev/mmcblk0p2 rootwait earlyprintk \n\
uenvcmd=run sdbootfit \n\
sdbootfit=echo Run uEnv.txt copying Linux from SD to RAM... && \n\
fatload mmc 0 0x1000000 fit.itb && \n\
echo Boot fit.itb from RAM && \n\
bootm 0x1000000;" > artifacts/uEnv.txt
cp build_dir/target-*/linux-zynq/Image artifacts/
cp build_dir/target-*/linux-zynq/linux-5.10.107/arch/arm/boot/dts/zynq-ebaz4205.dtb artifacts/
cp build_dir/target-*/linux-zynq/root.ext4 artifacts/
gzip -f -9n -c artifacts/Image > artifacts/Image.gz
scripts/mkits.sh -D ebang_zynq-ebaz4205 -o $(pwd)/artifacts/fit.its -k $(pwd)/artifacts/Image.gz -C gzip   -d $(pwd)/artifacts/zynq-ebaz4205.dtb   -a 0x8000 -e 0x8000    -c "config-1" -A arm -v 5.10.107
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
