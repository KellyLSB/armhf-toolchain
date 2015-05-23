#!/bin/bash


$(dirname $0)/dependencies.sh \
	-e debootstrap              \
	-e realpath                 #
	                            #
  # \\\ Dependencies \\\\\\\\\#


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
: ${CHROOT_PKGS:="sudo,wget,curl,git,ca-certificates"}
export CHROOT_ARCH CHROOT_DIST CHROOT_PATH CHROOT_REPO
printf "\n"

echo "Done"; sleep 2


$(dirname $0)/debootstrap.sh 		\
	--cache ${PROJECT_PATH}/cache #
																#
  # \\\ Debootstrap \\\\\\\\\\\\#


#
# Prepare an Apt-Cacher-Ng Proxy
#
export APT_CACHE_DOCKER="RUN echo No apt caching enabled."
if [[ "${APT_CACHE}" = "enabled" ]]; then
	APT_CACHE_DOCKER="\"Acquire::HTTP::Proxy \\\\\"${APT_CACHE_ADDR}\\\\\";\""
	APT_CACHE_DOCKER="RUN echo ${APT_CACHE_DOCKER} >> /etc/apt/apt.conf.d/01proxy"
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
