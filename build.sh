#!/bin/sh

# Version configuration
BOOTLOADER=u-boot-2010.03
KERNEL=linux-2.6.39.2
BUSYBOX=busybox-1.18.5

# Download source code for vboard
echo "Downloading bootloader sources..."
wget -c -P sources ftp://ftp.denx.de/pub/u-boot/${BOOTLOADER}.tar.bz2
echo "Downloading kernel sources..."
wget -c -P sources http://www.kernel.org/pub/linux/kernel/v2.6/${KERNEL}.tar.bz2
echo "Downloading busybox sources..."
wget -c -P sources http://busybox.net/downloads/${BUSYBOX}.tar.bz2
echo "Downloading qemu from trunk..."
git clone git://git.qemu.org/qemu.git

if [ ! -e sources ]; then
  mkdir sources
fi
if [ ! -e images ]; then
  mkdir images
fi

# Build bootloader
if [ ! -e .${BOOTLOADER}.build ]; then
  echo "******************************************************************"
  echo "* Unpacking ${BOOTLOADER}"
  echo "******************************************************************"
  tar xfvj sources/${BOOTLOADER}.tar.bz2
  echo "******************************************************************"
  echo "* Patching ${BOOTLOADER}"
  echo "******************************************************************"
  cd ${BOOTLOADER}
  patch -p1 < ../patch/u-boot-2010.03-ramdisk.patch 
  echo "******************************************************************"
  echo "* Configuring ${BOOTLOADER}"
  echo "******************************************************************"
  make CROSS_COMPILE=arm-none-eabi- versatilepb_config
  echo "******************************************************************"
  echo "* Building ${BOOTLOADER}"
  echo "******************************************************************"
  make MAKEINFO=makeinfo CROSS_COMPILE=arm-none-eabi- || exit
  cp u-boot.bin ../images
  cd ..
  touch .${BOOTLOADER}.build
fi

# Build kernel
if [ ! -e .${KERNEL}.build ]; then
  echo "******************************************************************"
  echo "* Unpacking ${KERNEL}"
  echo "******************************************************************"
  tar xfvj sources/${KERNEL}.tar.bz2
  echo "******************************************************************"
  echo "* Patching ${KERNEL}"
  echo "******************************************************************"
  cd ${KERNEL}
  # Used new configure for versatile_defconfig
  cp ../configs/versatile_qemu_defconfig arch/arm/configs/versatile_defconfig
  echo "******************************************************************"
  echo "* Configuring ${KERNEL}"
  echo "******************************************************************"
  make ARCH=arm versatile_defconfig
  echo "******************************************************************"
  echo "* Building ${KERNEL}"
  echo "******************************************************************"
  make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- all || exit
  cp arch/arm/boot/zImage ../images
  cd ..
  touch .${KERNEL}.build
fi

# Build busybox
if [ ! -e .${BUSYBOX}.build ]; then
  echo "******************************************************************"
  echo "* Unpacking ${BUSYBOX}"
  echo "******************************************************************"
  tar xfvj sources/${BUSYBOX}.tar.bz2
  echo "******************************************************************"
  echo "* Patching ${BUSYBOX}"
  echo "******************************************************************"
  cd ${BUSYBOX}
  # Used new configure for busybox
  cp ../configs/busybox_qemu_defconfig .config
  echo "******************************************************************"
  echo "* Configuring ${BUSYBOX}"
  echo "******************************************************************"
  #make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- all
  echo "******************************************************************"
  echo "* Building ${BUSYBOX}"
  echo "******************************************************************"
  make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- all
  make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi- install || exit
  cd _install
  mkdir proc sys dev etc etc/init.d
  cp ../../rootfs/rcS etc/init.d
  find . | cpio -o --format=newc > ../rootfs.img
  cd ..
  gzip -c rootfs.img > rootfs.img.gz
  cp rootfs.img.gz ../images
  cd ..
  touch .${BUSYBOX}.build
fi


echo "******************************************************************"
echo "* Building flash.bin"
echo "******************************************************************"
cd images
if [ -e flash.bin ]; then
  rm -rf flash.bin
fi

mkimage -A arm -C none -O linux -T kernel -d zImage -a 0x00010000 -e 0x00010000 zImage.uimg

mkimage -A arm -C none -O linux -T ramdisk -d rootfs.img.gz -a 0x00800000 -e 0x00800000 rootfs.uimg

dd if=/dev/zero of=flash.bin bs=1 count=6M
dd if=u-boot.bin of=flash.bin conv=notrunc bs=1
dd if=zImage.uimg of=flash.bin conv=notrunc bs=1 seek=2M
dd if=rootfs.uimg of=flash.bin conv=notrunc bs=1 seek=4M

#/home/barry/source/qemu/arm-softmmu/qemu-system-arm -M versatilepb -m 128M -kernel flash.bin -serial stdio
#/home/barry/study/qemu/qemu/arm-softmmu/qemu-system-arm -M versatilepb -m 128M -kernel flash.bin -serial stdio

