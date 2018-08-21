{%- from "ltsp/map.jinja" import service with context %}
{%- if service.enabled %}

ltsp_pkgs:
  pkg.installed:
    - pkgs: {{ service.pkgs }}
{%- if 'qemu-user-static' in service.pkgs and grains.get('virtual_subtype') == 'Docker' %}
fix_qemu-user-static_postinst:
  cmd.run:
    - name: >
        sed -i.bak "s/grep.*container= .*environ.*exit 0/#&/" /var/lib/dpkg/info/qemu-user-static.postinst;
        dpkg-reconfigure qemu-user-static;
        mv /var/lib/dpkg/info/qemu-user-static.postinst{.bak,}
    - onchanges:
      - pkg: ltsp_pkgs
{%- endif %}

/usr/local/bin/nm_unmanage_device.py:
  file.managed:
    - source: salt://ltsp/files/nm_unmanage_device.py
    - mode: 755
    - require_in:
      - network: linux_interface_{{ service.iface }}

/usr/local/bin/ltsp_dnsmasq.sh:
  file.managed:
    - source: salt://ltsp/files/ltsp_dnsmasq.sh
    - template: jinja
    - mode: 755
    - makedirs: True

/etc/systemd/system/ltsp.service:
  file.managed:
    - source: salt://ltsp/files/ltsp.service
{%- if service.running and grains.get('noservices') %}
/etc/systemd/system/multi-user.target.wants/ltsp.service:
  file.symlink:
    - target: /etc/systemd/system/ltsp.service
    - require:
      - file: /etc/systemd/system/ltsp.service
    - require_in:
      - service: ltsp
{%- endif %}

ltsp:
{%- if service.running %}
  {%- if grains.get('noservices') %}
  service.enabled:
    - unless: /bin/true
  {%- else %}
  service.running:
    - enable: True
  {%- endif %}
    - watch:
      - network: linux_interface_{{ service.iface }}
      - file: /etc/systemd/system/ltsp.service
      - file: /usr/local/bin/ltsp_dnsmasq.sh
      - pkg: ltsp_pkgs
{%- else %}
  service.dead:
    - enable: False
    - require:
      - file: /etc/systemd/system/ltsp.service
{%- endif %}

{%- endif %}
