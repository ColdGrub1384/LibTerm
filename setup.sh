#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$DIR"

# Update submodules

git submodule update --init --recursive

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

ios_system="https://github.com/holzschu/ios_system/releases/download/v2.2/release.tar.gz"
ios_system_v32="https://github.com/holzschu/ios_system/releases/download/v2.3/release.tar.gz"

# Download and setup ios_system

mkdir ios_system

curl -L $ios_system -o ios_system.tar.gz
tar -xzf ios_system.tar.gz -Cios_system/
mv ios_system/release/* ios_system/
rm -rf ios_system/network_ios.framework
rm -rf ios_system/release
rm ios_system.tar.gz

# Download and setupt network from ios_system 3.2

mkdir ios_system32

curl -L $ios_system_v32 -o ios_system.tar.gz
tar -xzf ios_system.tar.gz -Cios_system32/
mv ios_system32/release/* ios_system32/
rm -rf ios_system32/release
mv ios_system32/network_ios.framework ios_system/
rm -rf ios_system32
rm ios_system.tar.gz

# bc

cd bc
sh ./get_frameworks.sh
make
cd ../
