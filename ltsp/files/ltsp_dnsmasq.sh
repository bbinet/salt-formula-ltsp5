{%- from "ltsp/map.jinja" import service with context %}
{%- set range = service.dhcp_range -%}

#!/bin/bash
#
# This file is managed by SaltStack
#

/usr/sbin/dnsmasq \
    --dhcp-range={{ range.start }},{{ range.end }},{{ range.lease }} \
    --dhcp-option=17,/opt/ltsp/armhf \
    --dhcp-vendorclass=etherboot,Etherboot \
    --dhcp-vendorclass=pxe,PXEClient \
    --dhcp-vendorclass=ltsp,"Linux ipconfig" \
    --dhcp-boot=net:pxe,/ltsp/armhf/pxelinux.0 \
    --dhcp-boot=net:etherboot,/ltsp/armhf/nbi.img \
    --dhcp-boot=net:ltsp,/ltsp/armhf/lts.conf \
    --dhcp-option=vendor:pxe,6,2b \
    --dhcp-no-override \
    --pxe-service=0,"Raspberry Pi Boot" \
    --enable-tftp \
    --tftp-root=/var/lib/tftpboot/ \
    --interface {{ service.iface }} \
    --bind-interfaces \
    --bogus-priv \
    --domain-needed \
    --conf-file \
    --keep-in-foreground
    #--pxe-service=X86PC, "Boot from network", /ltsp/armhf/pxelinux
