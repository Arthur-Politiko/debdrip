#!/bin/bash

#--------------------------------------------------
# Functions
#--------------------------------------------------
function vecho() { [ $verbose -eq 1 ] && echo "$@" || true; }

#set -x
#set -e
function showProgress() { 
  rep() { seq -s $2 $1 | tr -d '[:digit:]'; } # Generate a string of repeated characters
  [ $# -eq 0 ] || [ $# -gt 2 ] && return 
  [ $# -eq 1 ] && percent=$1 || percent=$(( $2 * 100 / $1 ))
  width=$(( $(tput cols) - 4)) # Get terminal width
  completed=$( rep $(($width * $percent / 100)) "#" )
  remaining=$( rep $(($width * (100 - $percent) / 100 )) "-" )
  progress_bar=$completed$remaining
  echo -ne "\033[2K$percent: [$progress_bar]\r" # \033[2K - Clear the line
}

#--------------------------------------------------
# Default configuration
# 
#--------------------------------------------------
repo_url="https://deb.mirror.yandex.ru/ubuntu"
basedir="/var/www/"
distr="noble"
index_url=""
destdir="myrepo"
verbose=1

vecho "Load latest repo files"

#--------------------------------------------------
# Parsing input parameters
# 
#--------------------------------------------------
for arg in "$@"; do
  key="${arg%%=*}"
  value="${arg#*=}"
  case $key in
    --repo_url) repo_url="$value" ;;
    --basedir) basedir="$value" ;;
    --distr) distr="$value" ;;
    --destdir) destdir="$value" ;;
    --verbose) verbose=1 ;;
    *) vecho "Unknown option: $key" ;;
  esac
done

# injects variables
[ -f ./debdrip.conf ] && {
  . ./debdrip.conf 
  vecho "Using configuration from debdrip.conf"
} || {
  vecho "Using default configuration"
}

mirror_dir="$basedir$destdir"

#--------------------------------------------------
# Check if the mirror_dir directory exists
#
#--------------------------------------------------
[ ! -d "$mirror_dir" ] && {
  vecho "Mirror directory does not exist: $mirror_dir"
  exit 1
}

#--------------------------------------------------
# Check if the remote source enables
#
#--------------------------------------------------
index_url="$repo_url/dists/$distr/main/binary-amd64/Packages.gz"
# echo $index_url
$( ! curl -sI "$index_url" >/dev/null ) && {
  vecho "Remote source does not exits: $index_url"
  exit 1
}

#--------------------------------------------------
# Load the index file
#
#--------------------------------------------------
$( ! curl -so /tmp/Packages.gz -f $index_url ) && {
  vecho "Error while loading index file: $index_url"
  exit 1
}

#--------------------------------------------------
# Unpack the index file
#
#--------------------------------------------------
gzip -fd /tmp/Packages.gz


#--------------------------------------------------
# Read the index file and download packages
#
#--------------------------------------------------
pkgs=$( sed -n 's/Filename: //p' /tmp/Packages )
pkgscnt=$( echo "$pkgs" | wc -l )
vecho "Total packages for upgrade is $pkgscnt"
i=0
echo "$pkgs" | while read -r pkgs_url; do
  # Indicator of progress
  showProgress $pkgscnt $((++i))

  # Dest package full name
  fullname="$basedir$destdir/$pkgs_url"
  fullpath=$( dirname "$fullname" )
 
  # Creates the same struct as on the server
  mkdir -p "$fullpath" 

  # load the package. 
  #vecho "Full path: $fullname"
  #vecho "Repository URL: $repo_url/$pkgs_url"
  curl -so "$fullname" -O "$repo_url/$pkgs_url"
done

vecho "All packages loaded successfully."