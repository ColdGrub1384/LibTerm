#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$DIR"

# Update submodules

git submodule update --init --recursive

# Get ios_system release URL

ios_system="$(curl -s 'https://api.github.com/repos/holzschu/ios_system/releases/latest' \
| grep browser_download_url | cut -d '"' -f 4)"
ios_system=' ' read -r -a array <<< "$ios_system"

for url in $ios_system
do
if [[ "$url" == *release.tar.gz ]]
then
ios_system=$url
fi
done

# Download and setup ios_system

mkdir ios_system

curl -L $ios_system -o ios_system.tar.gz
tar -xzf ios_system.tar.gz -Cios_system/
mv ios_system/release/* ios_system/
rm -rf ios_system/release
rm ios_system.tar.gz

# bc

cd bc
sh ./get_frameworks.sh
make
cd ../
