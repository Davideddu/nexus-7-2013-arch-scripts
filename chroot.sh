#!/system/xbin/env ash

ROM_NAME="ArchLinux"
unset _chroot
#_chroot="/data/arch"
unset _actual_chroot
#_actual
_chroot="/data/media/0/multirom/roms/$ROM_NAME/root/"
unset _tmp
_tmp="/sdcard/losetup.txt"
unset _rootfsimage
_rootfsimage="/data/media/0/multirom/roms/$ROM_NAME/root.img"

# # Checking if losetup is done
# busybox [ -e "$_tmp" ] && rm -f $_tmp
# busybox losetup > $_tmp
# unset _line

# echo >> "$_tmp"
# while read _line; do
#    case "$_line" in
#       *"root.img"* )
#          echo "Loop found."
#          break
#       ;;
#       * )
#          echo "Setting up loop"...
#          busybox mknod /dev/loop256 b 7 256 || echo "/dev/loop256 already exists, skipping..."
#          busybox losetup /dev/loop256 ${_rootfsimage} || exit 1
#       ;;
#    esac
# done < $_tmp

echo "Mounting file systems..."
# Android makes sure you're not able to run anything in data, preventing sudo and a lot of stuff from running. This fixes it while the chroot is running.
busybox mount -o remount,suid,exec,dev /data
#busybox mount -t ext4 -o rw,noatime /dev/block/loop256 $_chroot || exit 1
#busybox mount -o bind $_actual_chroot $_chroot || exit 1
busybox mount -o bind /dev/ $_chroot/dev
busybox mount -t proc proc $_chroot/proc
busybox mount -t sysfs sysfs $_chroot/sys
busybox mount -t devpts devpts $_chroot/dev/pts
busybox mount -o bind /sdcard $_chroot/media/sdcard
busybox mount -o bind /system $_chroot/media/system

USER=$1

# SELinux will be a pain in the ass when building stuff from AUR. It's better disabled.
echo "Setting SELinux policy to \"Permissive\"..."
setenforce "Permissive" || echo "Unable to set SELinux enforcing policy. You will not be able to use fakeroot or do some operations."

echo "Entering chroot..."
CHROOT_SETUP="export TERM=xterm-256color; mount -t proc proc /proc; mount -t sysfs sysfs /sys; ln -s /proc/self/fd /dev/fd; source /etc/profile; clear"

case $USER in
    *"root"* )
        busybox chroot $_chroot /usr/bin/env HOME=/root TERM="$TERM" PS1='\u:\w\$ ' PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/bash -c "${CHROOT_SETUP}; /bin/bash"
    ;;
    * )
        busybox chroot $_chroot /usr/bin/env HOME=/root TERM="$TERM" PS1='\u:\w\$ ' PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/bash -c "export HOME=/home/${USER}; ${CHROOT_SETUP}; su - ${USER}"
    ;;
esac

echo "Setting SELinux policy to \"Enforcing\"..."
setenforce "Enforcing"

echo "chroot exited. umount..."
umount $_chroot/media/sdcard
umount $_chroot/media/system
umount $_chroot/dev/pts
umount $_chroot/sys

# BUG!! This will kill *all* the other chroots when exiting!
# If you want to keep the other chroots running, brutally kill
# this script (e.g. kill the terminal)

echo "killing existing processes in chroot..."
#busybox fuser -mk $_chroot
ls /proc | while read proc; do
    if realpath "/proc/${proc}/exe" 2> /dev/null |  grep -q "${_chroot}"; then
        kill "$proc"
    fi
done

umount $_chroot/proc
umount $_chroot/dev
busybox mount -o remount,nosuid,noexec,nodev /data

#umount $_chroot
#echo "Deactivating loop..."
#busybox losetup -d /dev/loop256
echo "Done. Bye!"
busybox [ -e "$_tmp" ] && rm -f $_tmp
exit 0
