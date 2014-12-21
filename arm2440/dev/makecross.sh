#!/bin/bash



PRJROOT=/myex/arm2440_dev
MAKE_LOG=${PRJROOT}/cross.log
ARCH=arm
TARGET=arm-none-linux-gnueabi

#build dir
BUILD_TOOLS=${PRJROOT}/build_tools

#the cross compile tool chain
TOOLS=${PRJROOT}/tools
PREFIX=$TOOLS
TARGET_PREFIX=${PREFIX}/${TARGET}

#kernel
KERNEL=${PRJROOT}/kernel

#packages
binutils=binutils-2.21.1a.tar.bz2
kernel_src=linux-2.6.39.4.tar.gz
gcc_src=gcc-4.5.4.tar.gz
glibc_src=glibc-2.12.2.tar.gz
glibc_ports_src=glibc-ports-2.12.1.tar.gz
glibc_linuxthreads_src=glibc-linuxthreads-2.5.tar.bz2
gcc_version=4.5.4
export PATH=${PREFIX}/bin:${PATH}

mkdir $TOOLS
mkdir $KERNEL
mkdir $BUILD_TOOLS
mkdir -p $TARGET_PREFIX


function check_ok()
{
	if [ $? !=  0 ];then
		echo "Error: $0"
		exit 0
	fi
}


sep_text="##################################################################"


echo "Enter Directory: $KERNEL"
cd $KERNEL
echo "tar -xf $kernel_src"
#tar -xf $kernel_src 
kernel_src_dir="$( echo $kernel_src | sed -e s/.tar.gz// -e s/.tar.bz2// )"
#echo $kernel_src_dir
#scan kernel source dir for kernel choose
#kernel_list=$(ls ./)
#kernel_array=""
#count=0
#ck=0
#for kernel_src_choose in $kernel_list
#do
#	echo "[$count] $kernel_src_choose"
#	kernel_array[$count]=$kernel_src_choose
# 	count=$(( count + 1 ))
#	
#done
#
##read -p "Choose kernel src dir[0-$(( count - 1 ))]:" ck
#echo ${kernel_array[0]}
#echo ${kernel_list[${ck}]}
#kernel_src=${kernel_array[$ck]}
echo "Enter Directory: $kernel_src_dir"
cd $kernel_src_dir

if [ ! -f include/linux/version.h ]
then
echo "make ARCH=arm CROSS_COMPILE=${TARGET}- menuconfig"
make ARCH=arm CROSS_COMPILE=${TARGET} menuconfig
echo "make ARCH=arm CROSS_COMPILE=${TARGET}- include/linux/version.h"
make ARCH=arm CROSS_COMPILE=${TARGET} include/linux/version.h
fi

echo "mkdir -p ${TARGET_PREFIX}/include"
mkdir -p ${TARGET_PREFIX}/include

cp -r include/linux ${TARGET_PREFIX}/include

cp -r arch/arm/include/asm ${TARGET_PREFIX}/include/asm

check_ok "Copy arch/arm/include/asm"

cp -r include/asm-generic  ${TARGET_PREFIX}/include/

#cp include/linux/version.h ${TARGET_PREFIX}/include/linux


echo "Enter Directory: ${BUILD_TOOLS}"
cd ${BUILD_TOOLS}
#echo $(pwd)
mkdir build_binutils
mkdir build_boot_gcc
mkdir build_glibc
mkdir build_glibc_header
mkdir build_gcc


echo "
${sep_text}
Build binutils:
${sep_text}
"

is_build="$( cat $MAKE_LOG | egrep build_binutils_done )"
echo $is_build
if [ "${is_build}" != "build_binutils_done" ]
then

echo "Enter Directory: ${BUILD_TOOLS}"
cd ${BUILD_TOOLS}

#echo "Extract $binutils"
#echo "$(basename $BUILD_TOOLS)"
binutils_dir="$( echo $binutils | sed -e s/[a-z].tar.gz// -e s/[a-z].tar.bz2//)"
if [ ! -d ${binutils_dir} ]
then
  	echo "tar  -xf $binutils -C ${BUILD_TOOLS}/"
	tar -xf $binutils
fi
echo "Enter Directory: build_binutils"

cd ./build_binutils

# No Native Language Support
echo "../${binutils_dir}/configure --prefix=${PREFIX} --target=${TARGET} --disable-nls"
../${binutils_dir}/configure --prefix=${PREFIX} --target=${TARGET} --disable-nls

check_ok "configure binuitls failed"

make

check_ok "make binutils failed"

make install

echo "
Build Binutils Successfully
"

echo "build_binutils_done" > $MAKE_LOG

fi
echo "
${sep_text}
Install glibc headers 
${sep_text}
"
is_build="$( cat $MAKE_LOG | egrep build_glibc_header_done )"
echo "$is_build"

if [ "$is_build" != "build_glibc_header_done" ]
then
	echo "Enter Directory: $BUILD_TOOLS"
	cd $BUILD_TOOLS
   	glibc_src_dir="$( echo $glibc_src | sed -e s/.tar.gz// -e s/.tar.bz2//)"

	if [ ! -d ${glibc_src_dir} ]
	then
 		echo "tar  -xf $glibc_src"
		tar -xf $glibc_src
	fi

	glibc_ports_dir="$( echo $glibc_ports_src |  sed -e s/.tar.gz// -e s/.tar.bz2//)"
	
	if [ ! -d ${glibc_src_dir}/${glibc_ports_dir} ]
	then
  		echo "tar -xf $glibc_ports_src -C ${glibc_src_dir}"
		tar -xf $glibc_ports_src -C ${glibc_src_dir}
		
	
	fi
	#for patch
	cp  ../sigrestorer.S ${glibc_src_dir}/${glibc_ports_dir}/sysdeps/unix/sysv/linux/arm/sigrestorer.S
	cp  ../sysdep-cancel.h ${glibc_src_dir}/${glibc_ports_dir}/sysdeps/unix/sysv/linux/arm/nptl/sysdep-cancel.h

	#cp  ../syscall-template.S ${glibc_src_dir}/sysdeps/unix/syscall-template.S

	#This is used by making libgcc
	if [ ! -d ${TARGET_PREFIX}/include/gnu ]
	then
		mkdir -p ${TARGET_PREFIX}/include/gnu
	fi

	touch ${TARGET_PREFIX}/include/gnu/stubs.h

#
#nptl has pthread.h
#
#	glibc_linuxthreads_dir="$( echo $glibc_linuxthreads_src | sed -e s/.tar.gz// -e s/.tar.bz2// )"
#	if [ ! -d ${glibc_src_dir}/${glibc_linuxthreads_dir} ]
#	then
#		echo "tar -xf $glibc_linuxthreads_src -C ${glibc_src_dir}"
#		tar -xf $glibc_linuxthreads_src -C ${glibc_src_dir}
#
#	fi
#
	echo "Enter Directory: build_glibc_header"
	cd build_glibc_header
	#Using host gcc to install glibc-headers
	echo "../${glibc_src_dir}/configure --prefix=/usr --host=${TARGET} --enable-add-ones=nptl \
  		--with-headers=${TARGET_PREFIX}/include --disable-nls \
		libc_cv_forced_unwind=yes \
		libc_cv_c_cl eanup=yes"
	../${glibc_src_dir}/configure --prefix="/usr" --host=${TARGET} --enable-add-ones=nptl --with-headers=${TARGET_PREFIX}/include libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes --disable-nls
	check_ok "configure glibc failed"
	# install_root does not work
	# prefix does not work in make
	# make cross-compiling=yes install_root=${TARGET_PREFIX} prefix="" install-headers
	# There is a file named config.Make used to config the install_root and prefix
	# and should set the install_root value and prefix value in the file
	#new_config_make="$( cat config.make  | sed -e s/install_root\\=/sss/ )"
	#echo $new_config_make
	#echo $new_config_make > config.make
	tp="$( echo ${TARGET_PREFIX} | sed -e 's/\//\\\//g')"
	#echo $tp
	
	echo "$( sed  -e s/install_root\ \=/install_root\ \=\ ${tp}/  config.make )" > config.make
	#echo "$( sed  -e 's/prefix\ \=\ \/usr/prefix\ \=/'  config.make )" > config.make
	#sed should see "\/" so \\/ is needed
	echo "$( sed  -e s/prefix\ \=\ \\/usr/prefix\ \=/  config.make )" > config.make
	echo "$( sed  -e s/cross-compiling\ \=\ maybe/cross-compiling\ \=\ yes\ / config.make )"  > config.make
	#read "dsa" ad
	make cross-compiling=yes install_root=${TARGET_PREFIX} prefix="" install-headers
	check_ok "make install glibc headers falied"
	echo "build_glibc_header_done" >> $MAKE_LOG
	echo "Build Glibc Header Successfully" 
fi

echo "
${sep_text}
Build Boot GCC
${sep_text}
"

is_build="$( cat $MAKE_LOG | egrep build_boot_gcc_done )"
echo "${is_build}"

if [ "${is_build}" != "build_boot_gcc_done" ]
then

echo "Enter Directory: $BUILD_TOOLS"
cd ${BUILD_TOOLS}

gcc_dir="$( echo $gcc_src | sed -e s/.tar.gz// -e s/.tar.bz2//)"

if [ ! -d ${gcc_dir} ]
then
  	echo "tar -xf $gcc_src"
	tar -xf $gcc_src 
fi

echo "Enter Directory: build_boot_gcc"

cd build_boot_gcc
#According to gcc.gnu.org/install/configure.html
echo "../${gcc_dir}/configure --prefix=${PREFIX} --target=${TARGET} --with-newlib --without-headers --enable-languages=c --disable-shared --disable-nls --with-cpu=arm9tdmi --with-arch=armv4t --with-tune=arm9tdmi --with-fpu=vfp --with-float=soft"
../${gcc_dir}/configure --prefix=${PREFIX} --target=${TARGET} --with-newlib --without-headers --enable-languages=c --disable-shared --disable-nls --with-cpu=arm9tdmi --with-arch=armv4t --with-tune=arm9tdmi --with-fpu=vfp --with-float=soft

#--without-headers does not work
#when make all-gcc , there is no erro
#but make all-target-gcc,pthread.h is needed
#pthread.s belongs to glibc-linuxthread and should be added to glibc first
#and install the headers to ${TARGET_PREFIX}/include

check_ok "configure gcc failed"

make all-gcc
make all-target-libgcc

check_ok "make all-gcc failed"

make install-gcc
make install-target-libgcc

check_ok "make install-gcc failed"

echo "build_boot_gcc_done" >> $MAKE_LOG
echo "Build Boot GCC Successfully"
fi

echo "
${sep_text}
Build Glibc With NTPL
${sep_text}
"


is_build="$( cat $MAKE_LOG | egrep "build_glibc_done")"
echo $is_build
if [ "${is_build}" != "build_glibc_done" ]
then
	echo "Enter Directory: $BUILD_TOOLS"
	cd ${BUILD_TOOLS}
  	glibc_src_dir="$( echo $glibc_src | sed -e s/.tar.gz// -e s/.tar.bz2//)"
	
	if [ ! -d ${glibc_src_dir} ]
	then
		echo "tar  -xf $glibc_src"
		tar -xf $glibc_src
	fi

	glibc_ports_dir="$( echo $glibc_ports_src |  sed -e s/.tar.gz// -e s/.tar.bz2//)"

	if [ ! -d ${glibc_src_dir}/${glibc_ports_dir} ]
	then
		echo "tar -xf $glibc_ports_src -C ${glibc_src_dir}"
		tar -xf $glibc_ports_src -C ${glibc_src_dir}
	
	fi
	#for patch
	cp  ../sigrestorer.S ${glibc_src_dir}/${glibc_ports_dir}/sysdeps/unix/sysv/linux/arm/sigrestorer.S
	#cp  ../syscall-template.S ${glibc_src_dir}/sysdeps/unix/syscall-template.S
	cp  ../sysdep-cancel.h ${glibc_src_dir}/${glibc_ports_dir}/sysdeps/unix/sysv/linux/arm/nptl/sysdep-cancel.h

	if [ ! -d ${TARGET_PREFIX}/include/gnu ]
	then
		mkdir -p ${TARGET_PREFIX}/include/gnu
	fi

	touch ${TARGET_PREFIX}/include/gnu/stubs.h

	echo "Enter Directory: build_glibc"
	cd build_glibc
	echo "CC=$TARGET-gcc ../${glibc_src_dir}/configure --prefix=/usr --host=${TARGET} --enable-add-ones=nptl \
 		--with-headers=${TARGET_PREFIX}/include \
		libc_cv_forced_unwind=yes \
		libc_cv_c_cl eanup=yes --disable-nls"
	CC=$TARGET-gcc ../${glibc_src_dir}/configure --prefix=/usr --host=${TARGET} --enable-add-ones=nptl --with-headers=${TARGET_PREFIX}/include libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes --disable-nls
	check_ok "configure glibc failed"
	
	#Patch for -lgcc_eh
	cp ${PREFIX}/lib/gcc/${TARGET}/${gcc_version}/libgcc.a ${PREFIX}/lib/gcc/${TARGET}/${gcc_version}/libgcc_eh.a 

	
	make
	check_ok "make glibc falied"

	tp="$( echo ${TARGET_PREFIX} | sed -e 's/\//\\\//g')"

	echo "$( sed  -e s/install_root\ \=/install_root\ \=\ ${tp}/  config.make )" > config.make
	#echo "$( sed  -e 's/prefix\ \=\ \/usr/prefix\ \=/'  config.make )" > config.make
	#sed should see "\/" so \\/ is needed
	echo "$( sed  -e s/prefix\ \=\ \\/usr/prefix\ \=/  config.make )" > config.make

	make install_root=${TARGET_PREFIX}/ prefix="" install
	check_ok "make install glibc falied"
	echo "build_glibc_done" >> $MAKE_LOG
	echo "Build Glibc  Successfully" 

fi

echo "
${sep_text}
Configure libc.so
${sep_text}
"

is_build="$( cat $MAKE_LOG | egrep "configure_libc_so_done")"
echo $is_build
if [ "${is_build}" != "configure_libc_so_done" ]
then
 	echo "Enter Directory: ${TARGET_PREFIX}/lib"
	cd ${TARGET_PREFIX}/lib
	echo "cp libc.so libc.so.org"
	cp libc.so libc.so.org
	echo "configure libc.so"
	echo "$(sed -e s/\\/lib\\///g libc.so )" > libc.so
	cat libc.so
	echo "Configure libc.so Successfully"
	 echo "configure_libc_so_done" >> $MAKE_LOG
fi

echo "
${sep_text}
Configure libpthread.so Patch For Build libgomp
${sep_text}
"

is_build="$( cat $MAKE_LOG | egrep "configure_libpthread_so_done")"
echo $is_build
if [ "${is_build}" != "configure_libpthread_so_done" ]
then
	echo "Enter Directory: ${BUILD_TOOLS}"
	cd ${BUILD_TOOLS}
 	echo "Enter Directory: ${TARGET_PREFIX}/lib"
	cd ${TARGET_PREFIX}/lib
	echo "cp libpthread.so libpthread.so.org"
	cp libpthread.so libpthread.so.org
	echo "configure libpthread.so"
	echo "$(sed -e s/\\/lib\\///g libpthread.so )" > libpthread.so
	cat libpthread.so
	echo "Configure libpthread.so Successfully"
	 echo "configure_libpthread_so_done" >> $MAKE_LOG
fi

echo "

${sep_text}
Build Full GCC
${sep_text}
"
is_build="$( cat $MAKE_LOG | egrep "build_gcc_done")"
echo $is_build
if [ "${is_build}" != "build_gcc_done" ]
then

echo "Enter Directory: ${BUILD_TOOLS}"
cd ${BUILD_TOOLS}

gcc_dir="$( echo $gcc_src | sed -e s/.tar.gz// -e s/.tar.bz2//)"

if [ ! -d ${gcc_dir} ]
then
  	echo "tar -xf $gcc_src"
	tar -xf $gcc_src 
fi

echo "Enter Directory: build_gcc"

cd build_gcc

#Need Patch for libgomp require PThreads 
#But Pthread is built
#Patch for configure.ac  configure of libgomp
#does not work just use --with-headers and --with-libs
#echo "../${gcc_dir}/configure --prefix=${PREFIX} --target=${TARGET}  --enable-languages=c,c++ --with-headers=${TARGET_PREFIX}/include --with-libs=${TARGET_PREFIX}/lib"
#../${gcc_dir}/configure --prefix=${PREFIX} --target=${TARGET} --enable-languages=c,c++ --with-headers=${TARGET_PREFIX}/include --with-libs=${TARGET_PREFIX}/lib
echo "../${gcc_dir}/configure --prefix=${PREFIX} --target=${TARGET}  --enable-languages=c,c++ --disable-nls --with-cpu=arm9tdmi --with-arch=armv4t --with-tune=arm9tdmi --with-fpu=vfp --with-float=soft
"
../${gcc_dir}/configure --prefix=${PREFIX} --target=${TARGET} --enable-languages=c,c++ --disable-nls --with-cpu=arm9tdmi --with-arch=armv4t --with-tune=arm9tdmi --with-fpu=vfp --with-float=soft


check_ok "configure gcc failed"

make all

check_ok "make all failed"

make install

check_ok "make install failed"

echo "build_gcc_done" >> $MAKE_LOG
echo "Build Full GCC Successfully"

fi


echo "
${sep_text}
Finally Setup
${sep_text}
"

echo "Enter Directory: ${TARGET_PREFIX}/bin"
cd ${TARGET_PREFIX}/bin
echo "Get Host Utils:"
host_utils="$( file * | egrep Intel | sed -e s/:.*// )"
echo $host_utils

for util in $host_utils
do
	echo "mv $util ${PREFIX}/libexec/gcc/${TARGET}/${gcc_version}/$util"
	mv $util ${PREFIX}/libexec/gcc/${TARGET}/${gcc_version}/$util
done

check_ok "mv utils error"

echo "Enter Directory: ${PREFIX}/libexec/gcc/${TARGET}/${gcc_version}"

cd ${PREFIX}/libexec/gcc/${TARGET}/${gcc_version}/
file * | grep "Intel"


echo "
${sep_text}
${TARGET} Cross Compiling Environment Create Successfully!
${sep_text}
"
