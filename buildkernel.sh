#!/bin/sh

# Colorize and add text parameters
red=$(tput setaf 1) # red
grn=$(tput setaf 2) # green
cya=$(tput setaf 6) # cyan
txtbld=$(tput bold) # Bold
bldred=${txtbld}$(tput setaf 1) # red
bldgrn=${txtbld}$(tput setaf 2) # green
bldblu=${txtbld}$(tput setaf 4) # blue
bldcya=${txtbld}$(tput setaf 6) # cyan
txtrst=$(tput sgr0) # Reset

export KERNELDIR=`readlink -f .`
export PARENT_DIR=`readlink -f ..`
export INITRAMFS_DEST=$KERNELDIR/kernel/usr/initramfs
export INITRAMFS_SOURCE=/home/khaon/Documents/kernels/Ramdisks/AOSP_ARIES
export PACKAGEDIR=/home/khaon/Documents/kernels/Packages/AOSP_Aries
export META_INF=/home/khaon/Documents/kernels/Packages/META-INF/Aries/META-INF
#Enable FIPS mode
export USE_SEC_FIPS_MODE=true
export ARCH=arm
export CROSS_COMPILE=/home/khaon/Documents/toolchains/arm-cortex_a15-linux-gnueabihf-linaro_4.9.2-2014.09/bin/arm-cortex_a15-linux-gnueabihf-

echo "${txtbld} Remove old Package Files ${txtrst}"
rm -rf $PACKAGEDIR/*

echo "${txtbld} Setup Package Directory ${txtrst}"
mkdir -p $PACKAGEDIR/system/lib/modules
mkdir -p $PACKAGEDIR/system/etc/init.d

echo "${txtbld} Create initramfs dir ${txtrst}"
mkdir -p $INITRAMFS_DEST

echo "${txtbld} Remove old initramfs dir ${txtrst}"
rm -rf $INITRAMFS_DEST/*

echo "${txtbld} Copy new initramfs dir ${txtrst}"
cp -R $INITRAMFS_SOURCE/* $INITRAMFS_DEST

echo "${txtbld} chmod initramfs dir ${txtrst}"
chmod -R g-w $INITRAMFS_DEST/*
rm $(find $INITRAMFS_DEST -name EMPTY_DIRECTORY -print)
rm -rf $(find $INITRAMFS_DEST -name .git -print)

echo "${txtbld} Remove old zImage ${txtrst}"
make mrproper
rm $PACKAGEDIR/zImage
rm arch/arm/boot/zImage

echo "${bldblu} Make the kernel ${txtrst}"
make khaon_aries_defconfig

make -j9

echo "${txtbld} Copy modules to Package ${txtrst} "
cp -a $(find . -name *.ko -print |grep -v initramfs) $PACKAGEDIR/system/lib/modules

echo "${txtbld} Copy scripts to init.d ${txtrst}"
cp $KERNELDIR/frandom/00frandom $PACKAGEDIR/system/etc/init.d

if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
	echo " ${bldgrn} Kernel built !! ${txtrst}"
	echo "Copy zImage to Package"
	cp arch/arm/boot/zImage $PACKAGEDIR/zImage

	echo "Make boot.img"
	./mkbootfs $INITRAMFS_DEST | gzip > $PACKAGEDIR/ramdisk.gz
	./mkbootimg --cmdline 'console=null androidboot.hardware=aries lpj=67677 user_debug=31 lge.kcal=0|0|0|x' --kernel $PACKAGEDIR/zImage --ramdisk $PACKAGEDIR/ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdiskaddr 0x82200000 --output $PACKAGEDIR/boot.img 
	export curdate=`date "+%d-%m-%Y"`
	cd $PACKAGEDIR
	cp -R $META_INF .
	rm ramdisk.gz
	rm zImage
	rm ../khaon_kernel_aries*.zip
	zip -r ../khaon_kernel_aries-$curdate.zip .
	cd $KERNELDIR
else
	echo "KERNEL DID NOT BUILD! no zImage exist"
fi;

