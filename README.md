# Armhf Build Toolchain

Based on Debian (jessie) this builds a Docker toolchain for building docker base images and cross compiling toolchains.

	$ git clone git://github.com/KellyLSB/armhf-toolchain.git
	$ cd armhf-toolchain
	$ export CHROOT_ARCH=armhf
	$ scripts/build.sh

## Environment

The container is presetup with cross compiling environment variables.

	$ echo $CROSS_COMPILE
	=> arm-linux-gnueabihf-
	$ echo $ARCH
	=> arm
