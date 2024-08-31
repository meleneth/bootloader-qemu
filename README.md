# bootloader-qemu

POC of a bootloader that will run a .c 'kernel' on a bare QEMU server.

The important trick is to install the cross compiler


sudo apt-get update
sudo apt-get install build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo


wget https://ftp.gnu.org/gnu/binutils/binutils-2.36.tar.gz
wget https://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.gz


tar -xzf binutils-2.36.tar.gz
tar -xzf gcc-10.2.0.tar.gz

mkdir build-binutils
cd build-binutils
../binutils-2.36/configure --target=i686-elf --prefix=/usr/local/cross --with-sysroot --disable-nls --disable-werror
make
sudo make install
cd ..

mkdir build-gcc
cd build-gcc
../gcc-10.2.0/configure --target=i686-elf --prefix=/usr/local/cross --disable-nls --enable-languages=c,c++ --without-headers
make all-gcc
make all-target-libgcc
sudo make install-gcc
sudo make install-target-libgcc
cd ..

make sure to add it to your path!

export PATH=/usr/local/cross/bin:$PATH



