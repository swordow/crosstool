#!/bin/bash

PRJROOT=/myex/arm2440_dev
ROOTFS=${PRJROOT}/rootfs
PREFIX=${PRJROOT}/tools
TARGET=arm-none-linux-gnueabi
TARGET_PREFIX=${PREFIX}/${TARGET}
BUILD_TOOLS=${PRJROOT}/build_tools
busybox_src=busybox-1.22.1.tar.bz2
mkroot_log=${PRJROOT}/rootfs.log
export PATH=${PREFIX}/bin:$PATH

stage1="$( cat $mkroot_log | grep "MAKE_ROOTFS_STAGE1_DONE")"

if [ "${stage1}" != "MAKE_ROOTFS_STAGE1_DONE" ]
then

if [ -d ${ROOTFS} ]
then
	rm -r -f ${ROOTFS}
fi
mkdir ${ROOTFS}
echo "Enter Dirctory: $ROOTFS"

cd $ROOTFS
if [ "$?" != "0" ]
then
	echo "No Directory: $ROOTFS"
	exit 0
fi
echo "mkdir usr bin sbin etc tmp var lib home root share"
mkdir usr bin sbin etc tmp var lib home root
echo "mkdir proc dev opt mnt"
mkdir proc dev opt mnt
echo "mkdir boot"
mkdir boot

echo "mkdir usr/bin usr/sbin usr/lib usr/modules"
mkdir usr/bin usr/sbin usr/lib usr/modules

echo "mkdir etc/rc.d etc/init.d etc/sysconfig"
mkdir etc/rc.d etc/init.d etc/sysconfig

echo "mknode dev/console dev/null"
sudo mknod -m 600 dev/console c 5 1
sudo mknod -m 600 dev/null c 1 3

echo "mkdir var/lib var/run var/tmp"
mkdir var/lib var/tmp var/run

echo "chmod 1777 var/tmp tmp"
chmod 1777 var/tmp
chmod 1777 tmp

#lib needed for os

cp_lib_done="$( cat $mkroot_log | grep "COPY_LIB_DONE")"
if [ "${cp_lib_done}" != "COPY_LIB_DONE" ]
then
echo "cp -d ${TARGET_PREFIX}/lib/* lib/*"
cp -r -f -d ${TARGET_PREFIX}/lib/* lib/
echo "COPY_LIB_DONE" > $mkroot_log 
fi

echo "Build BusyBox"
echo "Enter Directory: $BUILD_TOOLS"
cd $BUILD_TOOLS

busybox_src_dir="$( echo $busybox_src |  sed -e 's/.tar.gz//' -e 's/.tar.bz2//')"
if [ ! -f $busybox_src ]
then
echo "Download $busybox_src: wget http://www.busybox.net/download/$busybox_src"
	wget http://www.busybox.net/downloads/$busybox_src
fi
if [ ! -d $busybox_src_dir ]
then
	echo "tar -xf $busybox_src"
	tar -xf $busybox_src
fi

echo "copy ../busyconfig ./${busybox_src_dir}/.config"
cp ../busybox_config ./${busybox_src_dir}/.config

echo "copy mtd headers from kernel to ${TARGET_PREFIX}/include"
cp -r ../kernel/linux-2.6.39.4/include/mtd ${TARGET_PREFIX}/include/

echo "Enter Directory: $busybox_src_dir"
cd $busybox_src_dir

echo "CFLAGS=-march=armv4t make ARCH=arm CROSS_COMPILE=${TARGET}- CONFIG_PREFIX=${ROOTFS} clean"

CFLAGS=-march=armv4t make ARCH=arm CROSS_COMPILE=${TARGET}- CONFIG_PREFIX=${ROOTFS} clean

echo "CFLAGS=-march=armv4t make ARCH=arm CROSS_COMPILE=${TARGET}- CONFIG_PREFIX=${ROOTFS} install"
CFLAGS=-march=armv4t make ARCH=arm CROSS_COMPILE=${TARGET}- CONFIG_PREFIX=${ROOTFS} install
#echo "make ARCH=arm CROSS_COMPILE=${TARGET}- menuconfig"



echo "MAKE_ROOTFS_STAGE1_DONE" >> $mkroot_log

fi

echo "Enter Directory: $PRJROOT"

echo "copy host /etc/group /etc/shadow /etc/passwd to $ROOTFS/etc "
sudo cp /etc/group $ROOTFS/etc/group
sudo chown zenki:zenki $ROOTFS/etc/group
sudo cp /etc/shadow $ROOTFS/etc/shadow
sudo chown zenki:zenki $ROOTFS/etc/shadow
sudo cp /etc/passwd $ROOTFS/etc/passwd
sudo chown zenki:zenki $ROOTFS/etc/passwd

echo "Edit $ROOTFS/etc/inittab "

echo "#
::sysinit:/etc/init.d/rcS
console::askfirst:-/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r " > $ROOTFS/etc/inittab

echo "Edit $ROOTFS/etc/init.d/rcS "

echo "#!/bin/sh
PATH=/sbin:/bin:/usr/bin:/usr/sbin
runlevel=S
prevlevel=N
umask 022
export PATH runlevel prevlevel
mount -a
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
/bin/hostname ZENKI" > $ROOTFS/etc/init.d/rcS

chmod +x $ROOTFS/etc/init.d/rcS

echo "Edit $ROOTFS/etc/fstab"

echo "proc /proc proc defaults 0 0
none /tmp ramfs	defaults 0 0
sysfs /sys sysfs defaults 0 0
mdev /dev ramfs defaults 0 0" > $ROOTFS/etc/fstab

echo "Edit $ROOTFS/etc/profile"

echo "
USER=\"id -un\"
LOGNAME=\$USER
PS1='[\u@\h]#'
PATH=\$PATH
HOSTNAME='/bin/hostname'
export USER LOGNAME HOSTNAME" > $ROOTFS/etc/profile
