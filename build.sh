rm -rf flash.bin
#mkimage -A arm -C none -O linux -T kernel -d zImage -a 0x00010000 -e 0x00010000 zImage.uimg
mkimage -A arm -C none -O linux -T kernel -d ../kernel/linux-2.6.37/arch/arm/boot/zImage -a 0x00010000 -e 0x00010000 zImage.uimg

#mkimage -A arm -C none -O linux -T ramdisk -d rootfs.img.gz -a 0x00800000 -e 0x00800000 rootfs.uimg
mkimage -A arm -C none -O linux -T ramdisk -d ../busybox/rootfs.img.gz -a 0x00800000 -e 0x00800000 rootfs.uimg
dd if=/dev/zero of=flash.bin bs=1 count=6M
dd if=u-boot.bin of=flash.bin conv=notrunc bs=1
dd if=zImage.uimg of=flash.bin conv=notrunc bs=1 seek=2M
dd if=rootfs.uimg of=flash.bin conv=notrunc bs=1 seek=4M

#/home/barry/source/qemu/arm-softmmu/qemu-system-arm -M versatilepb -m 128M -kernel flash.bin -serial stdio
