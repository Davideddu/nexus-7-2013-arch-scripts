#!/system/xbin/env ash

CHROOT="/data/arch"
ROM_NAME="ArchLinux"
IMAGE="/data/media/0/multirom/roms/$ROM_NAME/root.img"

echo "Creating MultiROM rom directory..."
mkdir -p "/data/media/0/roms/$ROM_NAME"

echo "Downloading official BusyBox from busybox.net..."
mkdir -p "/data/local/tmp/arch/"
busybox wget -c http://busybox.net/downloads/binaries/latest/busybox-armv7l -O "/data/local/tmp/arch/busybox"
chmod 777 "/data/local/tmp/arch/busybox"

/data/local/tmp/arch/busybox echo "Busybox is working!" || exit 1

echo "Downloading ArchLinuxARM-trimslice-latest.tar.gz..."
busybox wget -c "http://nl.mirror.archlinuxarm.org/os/ArchLinuxARM-trimslice-latest.tar.gz"

echo "Making 4GB image..."
/data/local/tmp/arch/busybox dd if=/dev/zero of="${IMAGE}" bs=1M seek=4096 count=1 || exit 1

echo "Formatting image..."
/data/local/tmp/arch/busybox mke2fs -L arch-image -F "${IMAGE}" || exit 1
/data/local/tmp/arch/busybox mkdir ${CHROOT}

echo "Making devices..."
/data/local/tmp/arch/busybox mknod /dev/loop256 b 7 256 || exit 1
/data/local/tmp/arch/busybox losetup /dev/loop256 "${IMAGE}" || exit 1

echo "Mounting file systems..."
/data/local/tmp/arch/busybox mount -t ext4 -o rw,noatime /dev/block/loop256 ${CHROOT} || exit 1

echo "Extracting Arch system into image..."
/data/local/tmp/arch/busybox gunzip ArchLinuxARM-trimslice-latest.tar.gz -c | /data/local/tmp/arch/busybox tar x -f - -C ${CHROOT} || exit 1

echo "Adding directories..."
/data/local/tmp/arch/busybox mkdir -p ${CHROOT}/media/sdcard
/data/local/tmp/arch/busybox mkdir -p ${CHROOT}/media/system
/data/local/tmp/arch/busybox mkdir -p ${CHROOT}/dev/pts
/data/local/tmp/arch/busybox mkdir ${CHROOT}/dev/ptmx

echo "Mounting extra file systems..."
/data/local/tmp/arch/busybox mount -o bind /dev/ ${CHROOT}/dev || exit 1
/data/local/tmp/arch/busybox mount -t proc proc ${CHROOT}/proc || exit 1
/data/local/tmp/arch/busybox mount -t sysfs sysfs ${CHROOT}/sys || exit 1
/data/local/tmp/arch/busybox mount -t devpts devpts ${CHROOT}/dev/pts || exit 1
/data/local/tmp/arch/busybox mount -o bind /sdcard ${CHROOT}/media/sdcard || exit 1

echo "Setting SELinux policy to \"Permissive\"..."
setenforce "Permissive" || echo "Unable to set SELinux enforcing policy. You will not be able to use fakeroot or do some operations."

echo "Installing packages and upgrading system..."
echo -e "nameserver 208.67.222.222\nnameserver 208.67.220.220" > ${CHROOT}/etc/resolv.conf
echo "arch-flo" > ${CHROOT}/etc/hostname
/data/local/tmp/arch/busybox rm -rf ${CHROOT}/opt/nvidia
/data/local/tmp/arch/busybox rm -f ${CHROOT}/etc/ld.so.conf.d/nvidia-trimslice.conf
/data/local/tmp/arch/busybox chroot ${CHROOT} /usr/bin/env HOME=/root TERM="$TERM" PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/bash -c "source /etc/profile; groupadd -g 3003 aid_inet; groupadd -g 3004 inet; groupadd -g 3005 inetadmin; usermod -aG inet root; usermod -aG inetadmin root; pacman -Syyu --noconfirm; pacman -S --noconfirm xorg-server xorg-xrdb tigervnc xterm xorg-xsetroot xorg-xmodmap rxvt-unicode dwm pkg-config dmenu fakeroot zsh emacs vim git tmux mosh ruby python3 python2 sudo wget rsync base-devel; pacman -Rdd --noconfirm linux-firmware"

echo "Setting SELinux policy to \"Enforcing\"..."
setenforce "Enforcing"

echo "Exiting chroot, unmounting..."
umount ${CHROOT}/media/sdcard
umount ${CHROOT}/dev/pts
umount ${CHROOT}/proc
umount ${CHROOT}/sys

echo "Killing existing processes in chroot..."
/data/local/tmp/arch/busybox fuser -mk ${CHROOT}
umount ${CHROOT}/dev
umount ${CHROOT}

echo "Deactivating loop..."
/data/local/tmp/arch/busybox losetup -d /dev/loop256

#echo "Deleting ArchLinuxARM-trimslice-latest.tar.gz..."
#rm ArchLinuxARM-trimslice-latest.tar.gz

echo "Done."
echo "Note: as of now, you can only use Arch Linux as a chroot. If you want to boot it, you need to get a kernel and these files in the right locations:"
echo
echo "rom_info.txt:  /data/media/0/multirom/roms/$ROM_NAME/rom_info.txt"
echo "Kernel zImage: /data/media/0/multirom/roms/$ROM_NAME/boot/vmlinuz"
echo "               (chroot)/boot/vmlinuz"
echo "Initramfs:     /data/media/0/multirom/roms/$ROM_NAME/boot/initrd.img"
echo "               (chroot)/boot/initrd.img"
echo
echo "Then you will boot into Arch Linux (hopefully)."
echo "To change Arch Linux's icon in MultiROM use the MultiROM Manager application on Android."