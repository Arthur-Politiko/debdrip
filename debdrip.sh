#!/bin/bash

echo "Loadd latest repo files"
baseurl="https://deb.mirror.yandex.ru/ubuntu/"


#set -x
#set -e

# load the list of packages
wget -P /tmp https://deb.mirror.yandex.ru/ubuntu/dists/noble/main/binary-amd64/Packages.gz

gzip -fd /tmp/Packages.gz

pkgs=$( sed -n 's/Filename: //p' /tmp/Packages )
pkgscnt=$( echo "$pkgs" | wc -l )
echo "Total packeges for upgrade is "$pkgscnt

#for url in $( sed -n 's/Filename: //p' /tmp/Packages | head -n 2 )
#for url in $pkgs
echo "$pkgs" | while read -r url;
do

  #echo "Load a package: "$url
  mkdir -p $( dirname $url )
  #curl -o "./"$url -O $baseurl$url
  curl -sSf $baseurl$url -o "./$url"
done



