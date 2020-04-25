#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$DIR"

# Update submodules

git submodule update --init --recursive

rm ios_system/ios_system.m
cp ios_system.m ios_system_core/

# Get ios_system release URL

#ios_system="$(curl -s 'https://api.github.com/repos/holzschu/ios_system/releases/latest' \
#| grep browser_download_url | cut -d '"' -f 4)"
#ios_system=' ' read -r -a array <<< "$ios_system"

#for url in $ios_system
#do
#if [[ "$url" == *release.tar.gz ]]
#then
#ios_system=$url
#fi
#done

ios_system="https://github.com/holzschu/ios_system/releases/download/v2.4/release.tar.gz"

llvm="https://github.com/holzschu/llvm/releases/download/v0.4/release.tar.gz"

# Download and setup ios_system

mkdir ios_system

curl -L $ios_system -o ios_system.tar.gz
tar -xzf ios_system.tar.gz -Cios_system/
mv ios_system/release/* ios_system/
rm -rf ios_system/release
rm ios_system.tar.gz

# Download and setup llvm

mkdir llvm

curl -L $llvm -o llvm.tar.gz
tar -xzf llvm.tar.gz -Cllvm/
mv llvm/release/* llvm/
rm -rf llvm/release
rm llvm.tar.gz

# bc

cd bc
sh ./get_frameworks.sh
make
cd ../
