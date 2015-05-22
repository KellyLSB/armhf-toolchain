#!/bin/bash

function missing()  { ! sudo which $1 &>/dev/null; }
function nochroot() { ! [[ -f build/$1.tar.bz2 ]]; }

#
# Install missing dependencies.
#
if missing debootstrap && missing realpath; then
	echo "Updating Apt Sources"; sleep 1
	sudo apt-get -qq update
	echo "Done."; sleep 1

	echo "Installing Debootstrap and Realpath"; sleep 1
	sudo apt-get -qq install -y debootstrap realpath bzip2 tar
	echo "Done."; sleep 1
fi

#
# Setup project environment.
#
echo "Setting Project Environment"; sleep 1
printf "\n"

# Project environment variables
echo "Project Environment:"
: ${PROJECT_PATH:="$(realpath $(dirname $(dirname $0)))"}
echo -e "\tPROJECT_PATH => ${PROJECT_PATH}"
export PROJECT_PATH
printf "\n"

# Apt cache enironment variables
echo "Apt Cache Environment:"
: ${APT_CACHE:="disabled"}
echo -e "\tAPT_CACHE => ${APT_CACHE}"
: ${APT_CACHE_ADDR:="http://172.17.42.1:3142"}
echo -e "\tAPT_CACHE_ADDR => ${APT_CACHE_ADDR}"
export APT_CACHE APT_CACHE_ADDR
printf "\n"

# Chroot environment variables
echo "Chroot Environment:"
: ${CHROOT_ARCH:="amd64"}
echo -e "\tCHROOT_ARCH => ${CHROOT_ARCH}"
: ${CHROOT_DIST:="jessie"}
echo -e "\tCHROOT_DIST => ${CHROOT_DIST}"
: ${CHROOT_PATH:="$(mktemp -d)"}
echo -e "\tCHROOT_PATH => ${CHROOT_PATH}"
: ${CHROOT_REPO:="http://httpredir.debian.org/debian"}
echo -e "\tCHROOT_REPO => ${CHROOT_REPO}"
export CHROOT_ARCH CHROOT_DIST CHROOT_PATH CHROOT_REPO
printf "\n"

echo "Done"; sleep 2

#
# Create chroot and bundle it up.
#
if nochroot ${CHROOT_DIST}; then
	echo "Creating Chroot"; sleep 1
	sudo debootstrap ${CHROOT_DIST} ${CHROOT_PATH} ${CHROOT_REPO}
	echo "Done."; sleep 1

	echo "Archiving up Chroot"; sleep 1;
	cd ${CHROOT_PATH}; mkdir -p ${PROJECT_PATH}/build
	sudo tar -cpjvf ${PROJECT_PATH}/build/${CHROOT_DIST}.tar.bz2 *
	echo "Done."
fi

#
# Prepare an Apt-Cacher-Ng Proxy
#
if [[ "${APT_CACHE}" = "enabled" ]]; then
	APT_CACHE_DOCKER="\"Acquire::HTTP::Proxy \\\\\"${APT_CACHE_ADDR}\\\\\";\""
	APT_CACHE_DOCKER="RUN echo ${APT_CACHE_DOCKER} >> /etc/apt/apt.conf.d/01proxy"
	export APT_CACHE_DOCKER
fi

#
# Generate Dockerfile.
#
if ! [[ -f ${PROJECT_PATH}/Dockerfile ]]; then
	echo "Generating Dockerfile..."; sleep 1
	${PROJECT_PATH}/scripts/render-tpl.sh \
		${PROJECT_PATH}/tpls/Dockerfile-${CHROOT_ARCH} \
		${PROJECT_PATH}/Dockerfile
	echo "Done."; sleep 1
fi

#
# Build docker container
#
echo "Buildng debian-${CHROOT_DIST}-${CHROOT_ARCH} container."
sudo docker build -t debian-${CHROOT_DIST}-${CHROOT_ARCH} ${PROJECT_PATH}
rm ${PROJECT_PATH}/Dockerfile
echo "Done."
