#!/bin/bash

#
# Environment Variables
DEPS_LIST=()

#
# Get options
function usage() {
	cat <<-ENDHELP
  -e, --ensure-installed      :: Chroot directory
  -h, --help                  :: Show this message
	ENDHELP
}

getopt \
	-o e:h -Q \
	-l ensure-installed:,help -- "$@"

while true; do
	case "$1" in
    -e|--ensure-installed)  DEPS_LIST+=("$2");              shift 2;;
		-h|--help)              usage;                          exit 0 ;;
    *)                                                      break  ;;
	esac
done

#
# Check for usability of sudo
if ! which sudo &>/dev/null; then
  echo "This tool requires use of sudo." 1>&2
  exit 1
fi

#
# PackageKit
# Detect and install dependencies if needed.
function packagekit() {
  if ! which pkcon &>/dev/null; then
    echo "searching for packagekit... no" 1>&2
    return 1
  else
    echo "found packagekit..."
  fi

  #
  # Determine the status of a given package (installing if needed).
  while read status package dist; do
    package="$(sed -E 's/-[0-9\.-]+\..+//' <<<"$package")"

    case $status in
      Installed) echo "found $package $dist..."                       ;;
      Available) sudo pkcon -p install $package | grep -Ev '^[^ ]+:'  ;;
      *) echo "packagekit error: $status $package $dist!"; exit 1     ;;
    esac
  done <<<"$(sudo pkcon -p resolve ${DEPS_LIST[@]} | grep -Ev '^[^ ]+:')"
}

#
# Apt-Get
# Detect and install dependencies if needed.
function aptget() {
  if ! which apt-get &>/dev/null; then
    echo "searcing for apt-get... no" 1>&2
    return 1
  else
    echo "found apt-get"
  fi

  sudo apt-get -qy update
  sudo apt-get -qy install ${DEPS_LIST}
}

#
# Try handling dependencies with the follow package managers.
if [[ -n ${DEPS_LIST} ]]; then
  packagekit  && exit 0
  aptget      && exit 0

  #
  # No package manager was found to handle the given task.
  echo "No package manager found to handle dependencies!" 1>&2
  exit 1
fi

#
# No packages to install
echo "No dependencies were provided!"
