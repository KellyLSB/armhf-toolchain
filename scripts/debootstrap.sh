#!/bin/bash

#
# Environment Variables
DEBOOTSTRAP_ARGS=()
DEBOOTSTRAP_PKGS=(
  "sudo"
  "ca-certificates"
  "curl"
  "wget"
  "git"
  "ssh"
  "apt-utils"
)

: ${DEBOOTSTRAP_CACHE:="/tmp"}
: ${DEBOOTSTRAP_DIST:="jessie"}
: ${DEBOOTSTRAP_REPO:="http://httpredir.debian.org/debian"}
: ${DEBOOTSTRAP_ROOT:="$(mktemp -d)"}


#
# Get options
function usage() {
	cat <<-ENDHELP
  -r, --root      :: Chroot directory
                  => ${DEBOOTSTRAP_ROOT}
  -a, --arch      :: Deploy alternate architecture
  -d, --dist      :: Distribution name
                  => ${DEBOOTSTRAP_DIST}
  -k, --keyring   :: Archive Repo Keyring
  -r, --repo      :: Package Repo Address
                  => ${DEBOOTSTRAP_REPO}
  -p, --pkg       :: Include Packages
  -v, --variant   :: Debootstrap Variant
  -c, --cache     :: Package/Chroot Tarball Cache Directory
                  => ${DEBOOTSTRAP_CACHE}
  -h, --help      :: Show usage information
	ENDHELP
}

getopt \
	-o r:a:d:k:r:p:v:c:h -Q \
	-l root:,arch:,dist:,keyring:,repo:,pkgs:,variant:,cache:,help -- "$@"

while true; do
	case "$1" in
    -r|--repo)        DEBOOTSTRAP_ROOT="$2";                shift 2;;
		-a|--arch)        DEBOOTSTRAP_ARGS+=("--foreign=$2");   shift 2;;
		-d|--dist)        DEBOOTSTRAP_DIST="$2";                shift 2;;
		-k|--keyring)     DEBOOTSTRAP_ARGS+=("--keyring=$2");   shift 2;;
		-r|--repo)        DEBOOTSTRAP_REPO="$2";                shift 2;;
		-p|--pkg|--pkgs)  DEBOOTSTRAP_PKGS+=("$2");             shift 2;;
		-v|--variant)     DEBOOTSTRAP_ARGS+=("--variant=$2");   shift 2;;
		-c|--cache)       DEBOOTSTRAP_CACHE="$2";               shift 2;;
		-h|--help)        usage;                                exit 0 ;;
    *)                                                      break  ;;
	esac
done

#
# Join the packages into the include arguments.
if ! [[ -f ${DEBOOTSTRAP_CACHE}/${DEBOOTSTRAP_DIST}.tar.bz2  ]] && \
   ! [[ -f ${DEBOOTSTRAP_CACHE}/${DEBOOTSTRAP_DIST}.debs.tgz ]] && \
     [[ -n ${DEBOOTSTRAP_PKGS} ]]; then
  echo "Including the following packages"
  for pkg in ${DEBOOTSTRAP_PKGS[@]}; do echo -e "\t$pkg"; done
  DEBOOTSTRAP_ARGS+=("--include=$(echo ${DEBOOTSTRAP_PKGS[@]} | tr ' ' ',')")
fi

#
# Package up the debs into a tarball to be cached.
if ! [[ -f ${DEBOOTSTRAP_CACHE}/${DEBOOTSTRAP_DIST}.debs.tgz ]]; then
  echo "Downloading debs for choot from ${DEBOOTSTRAP_REPO}"
  sudo debootstrap ${DEBOOTSTRAP_ARGS[@]} \
    --make-tarball=${DEBOOTSTRAP_CACHE}/${DEBOOTSTRAP_DIST}.debs.tgz \
    ${DEBOOTSTRAP_DIST} ${DEBOOTSTRAP_ROOT} ${DEBOOTSTRAP_REPO}
fi

#
# Create a chroot and bootstrap it using the debs from the cache.
if ! [[ -f ${DEBOOTSTRAP_CACHE}/${DEBOOTSTRAP_DIST}.tar.bz2  ]] && \
     [[ -f ${DEBOOTSTRAP_CACHE}/${DEBOOTSTRAP_DIST}.debs.tgz ]]; then
  echo "Creating chroot in ${DEBOOTSTRAP_ROOT}"
  sudo debootstrap ${DEBOOTSTRAP_ARGS[@]} \
    --unpack-tarball=${DEBOOTSTRAP_CACHE}/${DEBOOTSTRAP_DIST}.debs.tgz \
    ${DEBOOTSTRAP_DIST} ${DEBOOTSTRAP_ROOT} ${DEBOOTSTRAP_REPO}

  #
  # Archive the chroot contents and place it into the cache.
  if [[ $? -eq 0 ]]; then
    echo "Archiving up chroot ${DEBOOTSTRAP_ROOT}"
    echo "=> ${DEBOOTSTRAP_CACHE}/${DEBOOTSTRAP_DIST}.tar.bz2"

    cd ${DEBOOTSTRAP_ROOT}
    sudo tar --checkpoint -cjpf \
      ${DEBOOTSTRAP_CACHE}/${DEBOOTSTRAP_DIST}.tar.bz2 *
    cd -
  else
    echo "Cleaning up chroot ${DEBOOTSTRAP_ROOT}"
    rm -f ${DEBOOTSTRAP_ROOT}
  fi
fi
