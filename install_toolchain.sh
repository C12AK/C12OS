#!/bin/bash

# 设置源码和安装路径
export TOOLCHAIN_SRC=~/opt/i386-elf-src
export INSTALL_PREFIX=/usr/local/i386-elf
mkdir -p "$TOOLCHAIN_SRC"
cd "$TOOLCHAIN_SRC"

# 安装依赖
sudo apt update
sudo apt install -y build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo

# 下载源码
wget https://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.gz
wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.gz

# 解压源码
tar -xzf binutils-2.40.tar.gz
tar -xzf gcc-13.2.0.tar.gz

# 编译 binutils
mkdir -p binutils-build
cd binutils-build
../binutils-2.40/configure --target=i386-elf --prefix="$INSTALL_PREFIX" --disable-nls --disable-werror
make -j$(nproc)
sudo make install
cd ..

# 编译 gcc（只编译 C 前端）
mkdir -p gcc-build
cd gcc-build
../gcc-13.2.0/configure --target=i386-elf --prefix="$INSTALL_PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
make all-gcc -j$(nproc)
sudo make install-gcc
cd ..
