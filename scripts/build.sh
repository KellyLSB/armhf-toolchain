#!/bin/bash

echo "Updating Apt Sources"; sleep 1
sudo apt-get -qq update
echo "Done."; sleep 1

echo "Installing Debootstrap and Realpath"; sleep 1
sudo apt-get -qq install -y debootstrap realpath
echo "Done."; sleep 1

echo "Setting Project Path"; sleep 1
: ${PROJECT_PATH:="$(realpath $(dirname $(dirname $0)))"}
echo "PROJECT_PATH => $PROJECT_PATH"; sleep 1
echo "Done"; sleep 1

echo "Creating Chroot"; sleep 1
: ${CHROOT_DIST:="jessie"}
: ${CHROOT_PATH:="$(mktemp -d)"}
: ${CHROOT_REPO:="http://httpredir.debian.org/debian"}
sudo debootstrap $CHROOT_DIST $CHROOT_PATH $CHROOT_REPO
echo "Done."; sleep 1

echo "Archiving up Chroot"; sleep 1;
cd $CHROOT_PATH; mkdir -p $PROJECT_PATH/build
sudo tar -cjvf $PROJECT_PATH/build/chroot.tar.bz2 *
echo "Done."

echo "Buildng debian-$CHROOT_DIST container."
sudo docker build -t debian-$CHROOT_DIST $PROJECT_PATH
