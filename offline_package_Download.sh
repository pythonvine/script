#!/bin/bash

APTGET=apt-get
APTCAC=apt-cache
APTFOLDER=/opt/aptdownloads
DOWNLOAD_LOCATION=/root/
sleep 1

# Check if apt-rdepends is installed
if ! command -v apt-rdepends &> /dev/null; then
    echo "apt-rdepends could not be found, installing it now..."
    sudo apt-get update
    sudo apt-get install -y apt-rdepends
fi

# Change directory to the download location
cd $DOWNLOAD_LOCATION

apt-get clean

rm -f error.txt

apt download $(apt-rdepends $1 | grep -v "^ " | grep -v "^$") 2> error.txt

if [ $(cat error.txt | wc -l) -gt 0 ]; then
    partial_command="\("

    while read -r line; do
        conflictive_package="$(awk '{split($0,array," "); print array[8]}' <<< $line)"
        partial_command="$partial_command$conflictive_package\|"

    done < error.txt

    partial_command="$(awk '{print substr($0, 1, length($0)-2)}' <<< $partial_command)\)"

    # Change directory to the download location

    cd $DOWNLOAD_LOCATION

    eval "apt download \$(apt-rdepends $1 | grep -v '^ ' | grep -v '^$partial_command$')"
fi
rm error.txt

# Create a tar.gz archive of all downloaded packages

tar -czvf $1.tar.gz *.deb --remove-files
