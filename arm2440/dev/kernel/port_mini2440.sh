#!/bin/bash

kernel_src=linux-2.6.39.4.tar.gz
kernel_version=2.6.39.4
kernel_src_dir="$( echo $kernel_src | sed -e s/.tar.gz// -e s/.tar.bz2//)"
default_s3c2440_config="s3c2440_defconfig"
TARGET=arm-none-linux-gnueabi
export PATH=/myex/arm2440_dev/tools/bin:$PATH
function xcd()
{
 	echo "Enter Directory: ${1}" 
	cd $1
	check_ok "No such directory."
}
function check_ok()
{
 	if [ "$?" == "1" ]
	then
 		echo "Error:${1}"
		exit 0
	fi
}
function debug_hold()
{
	read -p "Debug Hold" d
}
function set_kernel_config_value()
{
	echo "Modify: ${1}=${2}"
	echo "grep ${1}"
	cdl="$( cat .config | grep ${1} )"
	echo $cdl
	ncdl="$( echo ${cdl} | grep '#' )"
	if [ "$ncdl" == "" ]
	then
		echo "set ${1}=${2}"
		echo "$( cat .config | sed -e s/${1}.*/${1}\=${2}/)" > .config
	else
		echo "add ${1}=${2}"
		echo "${1}=${2}" >> .config
	fi

}


#PATCH leds_h1940.c


xcd $kernel_src_dir

cp ../leds-h1940.c drivers/leds/leds-h1940.c

#make ARCH=arm CROSS_COMPILE=${TARGET}- $default_s3c2440_config
check_ok "make $default_s3c2440_config error"
#make ARCH=arm CROSS_COMPILE=${TARGET}-
check_ok "make error"

echo "make clean"
make ARCH=arm CROSS_COMPILE=${TARGET}- clean


if [ ! -a arch/arm/mach-s3c2440/mach-mini2440.co ]
then
	echo "mv arch/arm/mach-s3c2440/mach-mini2440.c arch/arm/mach-s3c2440/mach-mini2440.co"
	mv arch/arm/mach-s3c2440/mach-mini2440.c arch/arm/mach-s3c2440/mach-mini2440.co
	
fi

if [ ! -a arch/arm/mach-s3c2440/mach-mini2440.c ]
then
	echo "cp arch/arm/mach-s3c2440/mach-smdk2440.c arch/arm/mach-s3c2440/mach-mini2440.c"
	cp arch/arm/mach-s3c2440/mach-smdk2440.c arch/arm/mach-s3c2440/mach-mini2440.c
fi

# Modify MACHINE_START
echo "Modify: SMDK2440 => MINI2440"
echo "$( cat arch/arm/mach-s3c2440/mach-mini2440.c | sed -e s/MACHINE_START\(.*\)/MACHINE_START\(MINI\2\4\4\0,\"ARM\ MINI\2\4\4\0\ Board\"\)/ )" > arch/arm/mach-s3c2440/mach-mini2440.c

# Modify CLK
echo "Modify: 16934400 => 12000000"
echo "$( cat arch/arm/mach-s3c2440/mach-mini2440.c | sed -e s/\1\6\9\3\4\4\0\0/\1\2\0\0\0\0\0\0/ )" > arch/arm/mach-s3c2440/mach-mini2440.c

# smdk2440 => mini2440
echo "Modify: smdk2440 => mini2440"
echo "$( cat arch/arm/mach-s3c2440/mach-mini2440.c | sed -e s/smdk\2\4\4\0/mini\2\4\4\0/g )" > arch/arm/mach-s3c2440/mach-mini2440.c

# comment smdk_machine_init()
echo "Modify: Comment smdk_machine_init"
echo "$( cat arch/arm/mach-s3c2440/mach-mini2440.c | sed -e s/smdk_machine_init\(\)/\\/\\/\&/g )" > arch/arm/mach-s3c2440/mach-mini2440.c

make ARCH=arm CROSS_COMPILE=${TARGET}- mini2440_defconfig
# using OABI not EABI 
# Modify .config to make CONFIG_AEABI=n
# but busybox will not work if no EABI
# so i need CONFIG_OABI_COMPAT set
#echo "Modify: CONFIG_AEABI=n"
#echo "$( cat .config | sed -e s/CONFIG_AEABI\=y/CONFIG_AEABI\=n/ )" > .config
echo "Modify: set CONFIG_AEABI=y
			  set CONFIG_OABI_COMPAT=y
CONFIG_AEABI is needed for build busybox"
set_kernel_config_value CONFIG_AEABI y
set_kernel_config_value CONFIG_OABI_COMPAT y 

#PATH arch/arm/Makefile
echo "Modify: arch/arm/Makefile CONFIG_AEABI -mfpu=vfp"
mfpu="$( cat arch/arm/Makefile | grep ":=\-mabi=aapcs\-linux \-mno\-thumb\-interwork" | grep "\-mfpu=vfp")"
echo "$mfpu"
if [ "$mfpu" == "" ]
then
echo "Modify: Path -mfpu=vfp"
echo "$(cat arch/arm/Makefile | sed -e "s/:\=\-mabi\=aapcs\-linux\ \-mno\-thumb\-interwork/&\ \-mfpu\=vfp/")" > arch/arm/Makefile
fi
# open Kernel-lowlevel-debug-function
# Modify: CONFIG_DEBUG_LL=y
echo "Modify: CONFIG_DEBUG_LL=y"
echo "grep CONFIG_DEBUG_LL"
cdl="$( cat .config | grep CONFIG_DEBUG_LL )"
echo $cdl
ncdl="$( echo ${cdl} | grep '#' )"
if [ "$ncdl" == "" ]
then
	echo "set CONFIG_DEBUG_LL=y"
	echo "$( cat .config | sed -e s/CONFIG_DEBUG_LL.*/CONFIG_DEBUG_LL\=y/)" > .config
else
	echo "add CONFIG_DEBUG_LL= y"
	echo "CONFIG_DEBUG_LL=y" >> .config
fi

#Before using NFS , must config NIC driver



#Using NFS to mount rootfs 
#echo "Modify: CONFIG_CMDLINE=\"noinitrd console=ttySAC0,115200 root=/dev/mtdblock3\""
echo "Modify: CONFIG_CMDLINE=\"noinitrd console=ttySAC0,115200 root=/dev/nfs rw nfsroot=192.168.8.1:/home/zenki/nfs/rootfs ip=192.168.8.2:192.168.8.1:255.255.255.0 init=/linuxrc mem=64M nfsrootdebug user_debug=31\""
#echo "$( cat .config | sed -e s/CONFIG_CMDLINE.*/CONFIG_CMDLINE\=\"noinitrd\ console\=ttySAC0,\1\1\5\2\0\0\ root\=\\/dev\\/mtdblock3\"/)" > .config

echo "$( cat .config | sed -e s/CONFIG_CMDLINE.*/CONFIG_CMDLINE\=\"noinitrd\ console\=ttySAC0,115200\ root\=\\/dev\\/nfs\ rw\ nfsroot\=192.168.8.1:\\/home\\/zenki\\/nfs\\/rootfs,tcp\ ip\=192.168.8.2:192.168.8.1:192.168.8.1:255.255.255.0\ init\=\\/linuxrc\ mem\=64M\ nfsrootdebug\ user_debug\=31\"/)" > .config
# If zImage built ok then add support to mini2440

#Modify: CONFIG_MACH_MINI2440=y support mini2440 board
echo "
Modify: .config
	CONFIG_MACH_MINI2440=y
	CONFIG_RTC_DRV_S3C=y 
	Support SamSung Serial SOC RTC
"

set_kernel_config_value CONFIG_MACH_MINI2440 y
set_kernel_config_value CONFIG_RTC_DRV_S3C y
#Modify: add arch/arm/mach-s3c2440/Makefile obj-$(CONFIG_MACH_MINI2440) += mach-mini2440.o

echo "Modify: arch/arm/mach-s3c2440/Makefile"
echo "grep obj-\$(CONFIG_MACH_MINI2440)"
is_obj_exist="$( cat arch/arm/mach-s3c2440/Makefile | grep obj-\$\(CONFIG_MACH_MINI2440\))"
echo "${is_obj_exist}"
if [ "${is_obj_exist}" == "" ]
then
	echo "add obj-\$\(CONFIG_MACH_MINI2440\) += mach-mini2440.o"
	echo "obj-\$(CONFIG_MACH_MINI2440) += mach-mini2440.o" >> arch/arm/mach-s3c2440/Makefile
fi

#Support Nand Flash Model
# drivers/mtd/nand/nand_ids.c

#Modify Nand Flash Partion Info
# arch/arm/plat-24xx/common-smdk.c
# add Code into arch/arm/mach-s3c2440/mach-mini2440.c

echo "Modify: arch/arm/mach-s3c2440/mach-mini2440.c nand part"
arm_nand_c="$( cat ../arm_nand.c | sed -e 's/\[/\\\[/g' -e 's/\]/\\\]/g' -e 's/\*/\\\*/g' -e 's/\"/\\\"/g' -e 's/\//\\\//g')"
arm_nand_c="$( echo $arm_nand_c | sed -e 's/\ /\\ /g')"
echo $arm_nand_c
echo "$(sed "151i${arm_nand_c}" arch/arm/mach-s3c2440/mach-mini2440.c)" > arch/arm/mach-s3c2440/mach-mini2440.c
#sed  '' arch/arm/mach-s3c2440/mach-mini2440.c

echo "
Modify: arch/arm/mach-s3c2440/mach-mini2440.c 
	reg nand device
	reg RTC device
	reg eth
"

echo "$( cat arch/arm/mach-s3c2440/mach-mini2440.c | sed -e 's/\&s3c_device_iis,/\&s3c_device_iis,\n\&s3c_device_nand,\n\&s3c_device_rtc,\n\&mini2440_device_eth,/'  )" > arch/arm/mach-s3c2440/mach-mini2440.c

echo "	
Modify: add nand headers
	add <linux/mtd/mtd.h>
	add <linux/mtd/partitions.h>
	add <plat/nand.h> // arch/arm/plat-samsung/plat/nand.h
"
echo "$( sed "16i#include <linux/mtd/mtd.h>\n#include <linux/mtd/partitions.h>\n#include<plat/nand.h>" arch/arm/mach-s3c2440/mach-mini2440.c)" > arch/arm/mach-s3c2440/mach-mini2440.c

#if not will using default platdata
#S3C24XX NAND Driver, (c) 2004 Simtec Electronics
#s3c24xx-nand s3c2440-nand: Tacls=4, 39ns Twrph0=8 79ns, Twrph1=8 79ns
#友善官方启动信息里这部分的内容是：
#S3C24XX NAND Driver, (c) 2004 Simtec Electronics
#s3c2440-nand s3c2440-nand: Tacls=3, 29ns Twrph0=7 69ns, Twrph1=3 29ns
#
echo "Modify: add s3c_nand_set_platdata( &mini2440_nand_info )"
echo "$(cat arch/arm/mach-s3c2440/mach-mini2440.c | sed -e "s/\/\/smdk_machine_init()/s3c_nand_set_platdata(\&mini2440_nand_info)/" )" > arch/arm/mach-s3c2440/mach-mini2440.c

echo "Modify: add DM9000 header"
echo "$( sed "52i#include <linux/dm9000.h>\n" arch/arm/mach-s3c2440/mach-mini2440.c)" > arch/arm/mach-s3c2440/mach-mini2440.c

#debug_hold

echo "Modity: add DM9000 Resource Code"
arm_dm9000_c="$( cat ../arm_dm9000.c | sed -e 's/\[/\\\[/g' -e 's/\]/\\\]/g' -e 's/\*/\\\*/g' -e 's/\"/\\\"/g' -e 's/\//\\\//g')"
arm_dm9000_c="$( echo $arm_dm9000_c | sed -e 's/\ /\\ /g' -e 's/\@\@\@\@/\\n/g')"
echo $arm_dm9000_c
echo "$(sed "53i${arm_dm9000_c}" arch/arm/mach-s3c2440/mach-mini2440.c)" > arch/arm/mach-s3c2440/mach-mini2440.c

#debug_hold
if [ ! -f ../dm9000.c ]
then
	echo "Backup: dm9000.c"
	cp drivers/net/dm9000.c ../dm9000.c
else
	cp ../dm9000.c drivers/net/dm9000.c
fi

echo "Modify: drivers/net/dm9000.c"
echo "$( sed "41i#if defined\(CONFIG_ARCH_S3C2410\)\n#include<mach/regs\-mem.h>\n#endif\n" drivers/net/dm9000.c)" > drivers/net/dm9000.c

#debug_hold

arm_dm9k_kernel_c="$( cat ../arm_dm9k_kernel.c | sed -e 's/\[/\\\[/g' -e 's/\]/\\\]/g' -e 's/\*/\\\*/g' -e 's/\"/\\\"/g' -e 's/\//\\\//g')"
arm_dm9k_kernel_c="$( echo $arm_dm9k_kernel_c | sed -e 's/\ /\\ /g' -e 's/\@\@\@\@/\\n/g' )"
echo $arm_dm9k_kernel_c
echo "$(sed "1708i${arm_dm9k_kernel_c}" drivers/net/dm9000.c)" > drivers/net/dm9000.c

#debug_hold

check_ok "Modify: DM9000"

echo "make zImage"

make ARCH=arm CROSS_COMPILE=${TARGET}- zImage

check_ok "make zImage"

