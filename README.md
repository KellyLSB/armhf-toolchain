# Armhf Build Toolchain

Based on Debian (jessie) this builds a Docker toolchain for cross compiling for armhf.

	$ git clone git://github.com/KellyLSB/armhf-toolchain.git
	$ scripts/build.sh

## Environment

The container is presetup with cross compiling environment variables.

	$ echo $CROSS_COMPILE
	=> arm-linux-gnueabihf-
	$ echo $ARCH
	=> arm
