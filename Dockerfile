FROM scratch
ADD build/chroot.tar.bz2 /
ADD conf/apt/sources.list /etc/apt/sources.list
ADD conf/apt/emdebian.list /etc/apt/sources.list.d/emdebian.list

ENV DEBIAN_FRONTEND noninteractive

RUN apt-key adv --keyserver keyserver.ubuntu.com \
		--recv-keys 7DE089671804772E

RUN dpkg --add-architecture armhf

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y crossbuild-essential-armhf \
	build-essential kernel-package debhelper \
	qemu-user-static 

ENV CROSS_COMPILE arm-linux-gnueabihf-
ENV ARCH arm
