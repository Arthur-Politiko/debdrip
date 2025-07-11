#!/bin/bash

echo "Load latest repo files"

baseurl="https://deb.mirror.yandex.ru/ubuntu/"
basedir="/var/www/"
distr="noble"
destdir="myrepo"

#set -x
#set -e

# load the index file of packages
if ! wget -P /tmp $baseurl/dists/$distr/main/binary-amd64/Packages.gz; then
  echo "Error while loading index-file"; exit 1
fi

gzip -fd /tmp/Packages.gz

pkgs=$( sed -n 's/Filename: //p' /tmp/Packages )
pkgscnt=$( echo "$pkgs" | wc -l )
echo "Total packages for upgrade is "$pkgscnt

echo "$pkgs" | while read -r url; do
  # Indicator of progress
  #echo "Load a package: "$url

  # Dest package full name
  fullname=$basedir$destdir"/"$url
  fullpath=$( dirname $fullname )
 
  # Creates the same struct as on the server
  mkdir -p $fullpath 

  # load the package. 
  curl -o $fullname -O $baseurl$url
  #curl -o "./"$url -O $baseurl$url
  #curl -sSf $baseurl$url -o "./$url"
done



