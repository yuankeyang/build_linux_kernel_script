#!/bin/bash

TOP = $HOME/teeny-linux

if [ -d "$TOP" ]; then
    mkdir $TOP
else
    rm -rf $TOP
    mkdir $TOP
fi

cd $TOP
curl https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.10.6.tar.xz | tar xJf -
curl https://busybox.net/downloads/busybox-1.26.2.tar.bz2 | tar xjf -
cd $TOP/busybox-1.26.2
mkdir -pv ../obj/busybox-x86
make O=../obj/busybox-x86 defconfig
make O=../obj/busybox-x86 menuconfig
# -> Busybox Settings
#   -> Build Options
# [ ] Build BusyBox as a static binary (no shared libs)

cd ../obj/busybox-x86
make -j2
make install

mkdir -pv $TOP/initramfs/x86-busybox
cd $TOP/initramfs/x86-busybox
mkdir -pv {bin,sbin,etc,proc,sys,usr/{bin,sbin}}
cp -av $TOP/obj/busybox-x86/_install/* .

echo "#!/bin/sh" >> init
echo "mount -t proc none /proc" >> init
echo "mount -t sysfs none /sys" >> init
echo "mknod -m 666 /dev/ttyS0 c 4 64" >> init
echo "echo -e \"\\\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds\\\n\"" >> init
echo "setsid  cttyhack sh" >> init
echo "exec /bin/sh" >> init

find . -print0 | cpio --null -ov --format=newc | gzip -9 > $TOP/obj/initramfs-busybox-x86.cpio.gz

cd cd $TOP/linux-4.10.6
make O=../obj/linux-x86-basic x86_64_defconfig
make O=../obj/linux-x86-basic -j2
cd $TOP

qemu-system-x86_64 -kernel obj/linux-x86-basic/arch/x86_64/boot/bzImage -initrd obj/initramfs-busybox-x86.cpio.gz -nographic -append "console=ttyS0"
