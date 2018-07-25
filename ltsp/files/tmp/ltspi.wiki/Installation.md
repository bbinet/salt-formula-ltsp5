# Prerequisites
* Running Ubuntu 16.04
* To "next" branch flashed Raspberry Pis for PXE boot. See: https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/net_tutorial.md "CLIENT CONFIGURATION". **_Attention:_** _The latest release 769 of the firmware does not work with the current Ubuntu kernel. You need to flash the Raspberry Pi with `sudo BRANCH=next rpi-update 1aafa469e2c5b0f39fee5ca7648114ac176a9372`_
* Two network interfaces otherwise the network configuration will fail.

# Installation
Become root
 
```
sudo su -
```
 
Install LTSP server and client management software epoptes
 
```
apt --yes --install-recommends install ltsp-server-standalone vim epoptes subversion dnsmasq qemu-user-static binfmt-support
```

Configure one network interface with the IP 192.168.67.1/24 via desktop or in terminal
 
* using NetworkManager
 
 ```
 nmcli c modify <CONNECTION of output from nmcli d status> ipv4.method manual ipv4.addresses 192.168.67.1/24 ipv4.never-default yes
 nmcli d reapply <name of device>
 ```
 
* irectly in /etc/network/interfaces

 ```
 cat << EOF >> /etc/network/interfaces
 auto <interface name from e.g. ip a>
 iface <interface name from e.g. ip a> inet static
 address 192.168.67.1/24
 EOF
 ```
 
Configure the dnsmasq service to provide DHCP for range 192.168.67.20-250 and tftp service
 
```
cat << EOF > /etc/dnsmasq.d/ltsp-server-dnsmasq.conf
dhcp-range=192.168.67.20,192.168.67.250,8h
dhcp-option=17,/opt/ltsp/armhf
pxe-service=0,"Raspberry Pi Boot"
enable-tftp
tftp-root=/var/lib/tftpboot/
EOF
```
 
Restart dnsmasq service
 
```
systemctl restart dnsmasq
```
 
Configure the building of the client with lubuntu-desktop. lubuntu-desktop can certainly be replaced with another preferred desktop.
 
```
cat << EOF > /etc/ltsp/ltsp-build-client-raspi2.conf
MOUNT_PACKAGE_DIR="/var/cache/apt/archives"
KERNEL_ARCH="raspi2"
FAT_CLIENT=1
FAT_CLIENT_DESKTOPS="lubuntu-desktop"
LATE_PACKAGES="dosfstools less nano vim ssh firefox epoptes-client"
EOF
```

Build the client
 
```
ltsp-build-client --arch armhf --config /etc/ltsp/ltsp-build-client-raspi2.conf
```
 
Change directory to /var/lib/tftpboot/
 
```
cd /var/lib/tftpboot/
```
 
Download the correct firmware for Raspberry Pi from Github unzip and extract it
 
```
wget https://github.com/Hexxeh/rpi-firmware/archive/1aafa469e2c5b0f39fee5ca7648114ac176a9372.zip
unzip 1aafa469e2c5b0f39fee5ca7648114ac176a9372.zip
mv rpi-firmware-1aafa469e2c5b0f39fee5ca7648114ac176a9372/* .
rmdir rpi-firmware-1aafa469e2c5b0f39fee5ca7648114ac176a9372
```
_This step is in combination with the flashing of the firmware (s. Prerequisites) evident or the lts 16.04 kernels won't boot._
 
Create symbolic links from kernel in /var/lib/tftpboot. It is important, that the symlink’s destination is relative to this  folder. Otherwise the tftp server’s chroot cannot follow it!

```
ln -s ltsp/armhf/vmlinuz vmlinuz && ln -s ltsp/armhf/initrd.img initrd.img
```
 
Create configuration file for Raspberry Pi boot
```
cat << EOF > config.txt
dtparam=i2c_arm=on
dtparam=spi=on
disable_overscan=1
hdmi_force_hotplug=1
kernel vmlinuz
initramfs initrd.img
start_x=1
EOF
```
 
Create the kernel command-line file

 ```
 cat << EOF > cmdline.txt
 dwc_otg.lpm_enable=0 console=serial0,115200 kgdboc=serial0,115200 console=tty1 init=/sbin/init-ltsp nbdroot=192.168.67.1:/opt/ltsp/armhf root=/dev/nbd0 elevator=deadline rootwait
 EOF
 ```
Enjoy your LTSP environment with Raspberry Pis!