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
export INITRAMFS_SOURCE=/home/khaon/Documents/kernels/Ramdisks/AOSP_ARIES
export ANY_KERNEL=/home/khaon/kernels/AnyKernel2
export PACKAGEDIR=/home/khaon/Documents/kernels/Packages/AOSP_ARIES
export META_INF=/home/khaon/kernels/zip_builders/Aries
#Enable FIPS mode
export USE_SEC_FIPS_MODE=true
export ARCH=arm
export CROSS_COMPILE=/home/khaon/Documents/toolchains/arm-cortex_a15-linux-gnueabihf-linaro_4.9.3-2014.12/bin/arm-cortex_a15-linux-gnueabihf-

echo "${txtbld} Remove old Package Files ${txtrst}"
rm -rf $PACKAGEDIR/*

echo "${txtbld} Setup Package Directory ${txtrst}"
mkdir -p $PACKAGEDIR/system/lib/modules
mkdir -p $PACKAGEDIR/system/etc/init.d
mkdir -p $PACKAGEDIR/system/bin

echo "${txtbld} Remove old zImage ${txtrst}"
make mrproper
rm $PACKAGEDIR/zImage
rm arch/arm/boot/zImage

echo "${bldblu} Make the kernel ${txtrst}"
make khaon_aries_defconfig

make -j9

echo "${txtbld} Copy modules to Package ${txtrst} "
cp -a $(find . -name *.ko -print |grep -v initramfs) $PACKAGEDIR/system/lib/modules

echo "${txtbld} Copy khaon's mount script"
cp mount_khaon_userdata.sh $PACKAGEDIR/system/bin/mount_ext4.sh
cp mount_khaon_userdata.sh $PACKAGEDIR/system/bin/mount_khaon_userdata.sh

echo "${txtbld} Copy scripts to init.d ${txtrst}"
cp $KERNELDIR/frandom/00frandom $PACKAGEDIR/system/etc/init.d

if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
	echo " ${bldgrn} Kernel built !! ${txtrst}"
	echo "Copy zImage to Package"
	cp arch/arm/boot/zImage $PACKAGEDIR/zImage

	echo "Make boot.img"
	./mkbootfs $INITRAMFS_SOURCE | lz4c -hc -l > $PACKAGEDIR/ramdisk.gz
	./mkbootimg --cmdline 'console=null androidboot.hardware=aries lpj=67677 user_debug=31 lge.kcal=0|0|0|x' --kernel $PACKAGEDIR/zImage --ramdisk $PACKAGEDIR/ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdiskaddr 0x82200000 --output $PACKAGEDIR/boot.img 
	export curdate=`date "+%d-%m-%Y"`
	cd $PACKAGEDIR
	cp -R $META_INF/* .
	rm ramdisk.gz
	rm zImage
	rm ../khaon_kernel_aries*.zip
	rm ../UPDATE-AnyKernel2-khaon-kernel-aries-kitkat*
	zip -r ../khaon_kernel_aries-$curdate.zip .
	echo "${txtbld} Make build for TDB users ${txtrst}"
	cp $KERNELDIR/mount_khaon_userdata_tdb.sh $PACKAGEDIR/system/bin/mount_khaon_userdata.sh
	cp $KERNELDIR/mount_khaon_userdata_tdb.sh $PACKAGEDIR/system/bin/mount_ext4.sh
	zip -r ../khaon_kernel_aries_tdb-$curdate.zip .

	echo "${txtbld} Make AnyKernel solution${txtrst}"
	cd $ANY_KERNEL;
  	git reset --hard;git clean -fdx;git checkout aries-cm11;
	cp $KERNELDIR/arch/arm/boot/zImage zImage

 	zip -r9 $PACKAGEDIR/../UPDATE-AnyKernel2-khaon-kernel-aries-kitkat-"${curdate}".zip * -x README UPDATE-AnyKernel2.zip .git *~
	cd $KERNELDIR
else
	echo "KERNEL DID NOT BUILD! no zImage exist"
fi;

