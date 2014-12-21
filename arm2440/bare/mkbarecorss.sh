#!/bin/bash
PRJROOT=/myex/arm2440_bare_dev
MAKE_LOG=${PRJROOT}/barecross.log
ARCH=arm
TARGET=arm-none-eabi

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
gcc_src=gcc-4.5.4.tar.gz
newlib_src=newlib-2.1.0.tar.gz
#glibc_src=glibc-2.12.2.tar.gz
#glibc_ports_src=glibc-ports-2.12.1.tar.gz
#glibc_linuxthreads_src=glibc-linuxthreads-2.5.tar.bz2
gcc_version=4.5.4
export PATH=${PREFIX}/bin:${PATH}

mkdir $TOOLS
mkdir $KERNEL
mkdir $BUILD_TOOLS
mkdir -p $TARGET_PREFIX
mkdir -p $TARGET_PREFIX/include

function check_ok()
{
	if [ $? !=  0 ];then
		echo "Error: $0"
	 	exit 0
	fi 
}


sep_text="##################################################################"

echo "Enter Directory: ${BUILD_TOOLS}"
cd ${BUILD_TOOLS}
#echo $(pwd)
mkdir build_binutils
mkdir build_boot_gcc
mkdir build_newlib
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
  	echo "t ar  -xf $binutils -C ${BUILD_TOOLS}/"
	tar -xf $binutils
fi
echo "Enter Directory: build_binutils"

cd ./build_binutils

echo "../${binutils_dir}/configure --prefix=${PREFIX} --target=${TARGET} --enable-interwork --enbale-multilib --disable-nls"

# --enable-interwork: is not supported in binutils
# --enable-multilib: is defaule enabled
# --disable-nls: no need other native language support

../${binutils_dir}/configure --prefix=${PREFIX} --target=${TARGET} --enable-interwork --enable-multilib --disable-nls
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
Install Newlib Include files
${sep_text}
"
echo "Enter Directory: $BUILD_TOOLS"
cd ${BUILD_TOOLS}

newlib_src_dir="$( echo $newlib_src | sed -e s/.tar.gz// -e s/.tar.bz2//)"
if [ ! -d $newlib_src_dir ]
then
	echo "tar -xf $new lib_src"
	tar -xf $newlib_src
fi

echo "cp -r -f ${newlib_src_dir}/newlib/libc/include/* "
cp -r -f ${newlib_src_dir}/newlib/libc/include/* ${TARGET_PREFIX}/include/

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
#c++ is not supported in boot_gcc
#lto link time optimition is not suppportted
#--with-headers will cause link to crt0.o test while configure newlib
echo "../${gcc_dir}/configure --prefix=${PREFIX} --target=${TARGET} --with-newlib --with-headers=${TARGET_PREFIX}/include --enable-languages=c --disable-shared --enable-interwork --enable-multilib --disable-nls --disable-lto"
../${gcc_dir}/configure --prefix=${PREFIX} --target=${TARGET} --with-newlib --with-headers=${TARGET_PREFIX}/include --enable-languages=c --disable-shared  --enable-interwork --enable-multilib --disable-nls --disable-lto

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
Build Newlib
${sep_text}
"


is_build="$( cat $MAKE_LOG | egrep "build_newlib_done")"
echo $is_build
if [ "${is_build}" != "build_newlib_done" ]
then
 	echo "Enter  Directory: $BUILD_TOOLS"
	cd ${BUILD_TOOLS}
  	newlib_src_dir="$( echo $newlib_src | sed -e s/.tar.gz// -e s/.tar.bz2//)"
	
	if [ ! -d ${newlib_src_dir} ]
	then
 		echo "tar  -xf $newlib_src"
		tar - xf $newlib_src
	fi
	#echo "Enter DIrectory: build_libgloss"
	#cd build_libgloss
	#echo "../${newlib_src_dir}/libgloss/configure --prefix=${PREFIX} --host"

	echo "Enter Directory: build_newlib"
	cd build_newlib
	#newlib no need to set host just target
	#the program built by this toolchain runs on the hardware not the os
	echo "../${newlib_src_dir}/configure --prefix=${PREFIX} --target=${TARGET} --enable-interwork --enable-multilib --disable-nls"
	../${newlib_src_dir}/configure --prefix=${PREFIX} --target=${TARGET} --enable-interwork --enable-multilib	--disable-nls
	check_ok "configure newlib failed"
	
	#Patch for build_tools/build_newlib/libgloss/arm/
	if [ ! -d ./${newlib_src_dir} ] 
	then
			echo "cp -r ../${newlib_src_dir} ./"
			cp -r ../${newlib_src_dir} ./
	fi
	#echo "$( cat ${TARGET}/libgloss/arm/cpu-init/Makefile | sed -e s/\.\.\\/\.\.\\/\.\.\\/\.\.\\//\.\.\\/\.\.\\/\.\.\\/\.\.\\/\.\.\\//)" > ${TARGET}/libgloss/arm/cpu-init/Makefile 
	#echo "$( cat ${TARGET}/thumb/libgloss/arm/cpu-init/Makefile | sed -e s/\.\.\\/\.\.\\/\.\.\\/\.\.\\/\.\.\\//\.\.\\/\.\.\\/\.\.\\/\.\.\\/\.\.\\/\.\.\\//)" > ${TARGET}/thumb/libgloss/arm/cpu-init/Makefile 

	#Patch for -lgcc_eh
	cp ${PREFIX}/lib/gcc/${TARGET}/${gcc_version}/libgcc.a ${PREFIX}/lib/gcc/${TARGET}/${gcc_version}/libgcc_eh.a 

	
	make
	check_ok "make newlib falied"
	make install
	check_ok "make install newlib falied"
	echo "build_newlib_done" >> $MAKE_LOG
	echo "Build Newlib Successfully" 

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
echo "../${gcc_dir}/configure --prefix=${PREFIX} --target=${TARGET} --with-newlib --with-headers=${TARGET_PREFIX}/include --enable-languages=c --disable-shared --enable-interwork --enable-multilib --disable-nls"
../${gcc_dir}/configure --prefix=${PREFIX} --target=${TARGET} --with-newlib --with-headers=${TARGET_PREFIX} --enable-languages=c --disable-shared  --enable-interwork --enable-multilib --disable-nls

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
