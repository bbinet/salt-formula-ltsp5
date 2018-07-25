#!/bin/bash

if [ -d "$1" ]
then
  echo "SD card content already available in directory $1..."
  exit 0
fi

mkdir "$1"

sudo apt install --no-install-recommends subversion
svn export --force https://github.com/raspberrypi/firmware/branches/stable/boot "$1"

rm -f "$1/{vmlinuz,initrd.img}"
ln -s /opt/ltsp/armhf/boot/{vmlinuz,initrd.img} "$1"
mkdir -p "$1/opt/ltsp"
ln -s /opt/ltsp/lts.conf "$1/opt/ltsp/lts.conf"

echo "# See https://www.raspberrypi.org/documentation/configuration/config-txt/README.md
# for many tuning options (e.g. monitor resolution) that you can put in this file.
kernel vmlinuz
initramfs initrd.img
# Enable audio (loads snd_bcm2835)
dtparam=audio=on
# Enable PXE boot
program_usb_boot_mode=1
" > $1/config.txt

echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 elevator=deadline rootwait init=/sbin/init-ltsp root=/dev/nbd0 nbdroot=192.168.67.1:/opt/ltsp/armhf" > $1/cmdline.txt
