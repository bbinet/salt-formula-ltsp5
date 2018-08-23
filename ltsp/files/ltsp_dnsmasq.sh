{%- from "ltsp/map.jinja" import service with context %}
{%- set cfg = service.dnsmasq -%}

#!/bin/bash
#
# This file is managed by SaltStack
#

/usr/sbin/dnsmasq \
    --enable-tftp \
    --tftp-root={{ cfg.tftp_root }} \
    --tftp-unique-root=mac \
    --interface {{ cfg.interface }} \
    --log-dhcp \
    --bind-interfaces \
    --bogus-priv \
    --domain-needed \
    --keep-in-foreground \
{%- for tag, tagcfg in cfg.get('tag', {}).items() %}
{%- set range = tagcfg.dhcp_range %}
{%- for host in tagcfg.dhcp_host %}
    --dhcp-host={{ host }},set:{{ tag }} \
{%- endfor %}
    --dhcp-range=tag:{{ tag }},{{ range.start }},{{ range.end }},{{ range.lease }} \
{%- if tagcfg.dhcp_boot %}
    --dhcp-boot=tag:{{ tag }},{{ tagcfg.dhcp_boot }} \
{%- endif %}
{%- if tagcfg.dhcp_reply_delay %}
    --dhcp-reply-delay=tag:{{ tag }},{{ tagcfg.dhcp_reply_delay }} \
{%- endif %}
{%- if tagcfg.pxe_service %}
    --pxe-service=tag:{{ tag }},{{ tagcfg.pxe_service }} \
{%- endif %}
{%- endfor %}
    --conf-file
