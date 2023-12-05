#!/usr/bin/env bash
# Download and build 2.42.0 git on Raspberry Pi
sudo apt update
sudo apt install make libssl-dev libghc-zlib-dev libcurl4-gnutls-dev libexpat1-dev gettext autoconf
cd /tmp/ || exit
wget https://github.com/git/git/archive/refs/tags/v2.42.0.tar.gz
tar -xzvf v2.42.0.tar.gz
cd /tmp/git-2.42.0/ || exit
./configure --prefix=/usr/local
make all
sudo make install
git --version
