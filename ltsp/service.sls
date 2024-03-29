{%- from "ltsp/map.jinja" import service with context %}
{%- if service.enabled %}

ltsp_pkgs:
  pkg.installed:
    - pkgs: {{ service.pkgs }}
    - require_in:
      - network: linux_interface_{{ service.iface }}
{%- if salt['pillar.get']('linux:system:repo', {})|length > 0 and salt['pillar.get']('linux:system:enabled', False) %}
    - require:
      - sls: linux.system.repo
{%- endif %}

{%- if service.multiarch and not grains.get('noservices') %}
ltsp_pkgs_multiarch:
  pkg.installed:
    - pkgs: {{ service.pkgs_multiarch }}
{%- if salt['pillar.get']('linux:system:repo', {})|length > 0 and salt['pillar.get']('linux:system:enabled', False) %}
    - require:
      - sls: linux.system.repo
{%- endif %}
{%- if 'qemu-user-static' in service.pkgs_multiarch and grains.get('virtual_subtype') == 'Docker' %}
fix_qemu-user-static_postinst:
  cmd.run:
    - name: >
        sed -i.bak "s/grep.*container= .*environ.*exit 0/#&/" /var/lib/dpkg/info/qemu-user-static.postinst;
        dpkg-reconfigure qemu-user-static;
        mv /var/lib/dpkg/info/qemu-user-static.postinst{.bak,}
    - onchanges:
      - pkg: ltsp_pkgs_multiarch
{%- endif %}
{%- endif %}

/usr/local/bin/nm_unmanage_device.py:
  file.managed:
    - source: salt://ltsp/files/nm_unmanage_device.py
    - mode: 755
    - require_in:
      - network: linux_interface_{{ service.iface }}

{{ service.etc }}/lts.conf:
  file.managed:
    - source: salt://ltsp/files/lts.conf
    - makedirs: True
    - template: jinja
    - require:
      - pkg: ltsp_pkgs
{{ service.tftproot }}:
  file.directory:
    - clean: True
{{ service.tftproot }}/ltsp:
  file.directory:
    - makedirs: True
    - require_in:
      - file: {{ service.tftproot }}
{%- for mac, chroot in service.get('mac', {}).items() %}
{{ service.tftproot }}/{{ mac | lower }}:
  file.symlink:
    - target: {{ service.chroot[chroot]._boot }}
    - makedirs: True
    - require_in:
      - file: {{ service.tftproot }}
{%- endfor %}
{%- for chroot, chrootcfg in service.get('chroot', {}).items() %}
{%- if service.chroot[chroot].get('_enabled') %}
{%- for fname, file in service.chroot[chroot].get('_boot_files', {}).items() %}
{{ service.chroot[chroot]._boot }}/{{ fname }}:
{# following code borrowed from linux/system/file.sls #}
{%- if file.symlink is defined %}
  file.symlink:
    - target: {{ file.symlink }}
{%- else %}
{%- if file.serialize is defined %}
  file.serialize:
    - formatter: {{ file.serialize }}
  {%- if file.contents is defined  %}
    - dataset: {{ file.contents|json }}
  {%- elif file.contents_pillar is defined %}
    - dataset_pillar: {{ file.contents_pillar }}
  {%- endif %}
{%- else %}
  file.managed:
    {%- if file.source is defined %}
    - source: {{ file.source }}
    {%- if file.hash is defined %}
    - source_hash: {{ file.hash }}
    {%- else %}
    - skip_verify: True
    {%- endif %}
    {%- elif file.contents is defined %}
    - contents: {{ file.contents|json }}
    {%- elif file.contents_pillar is defined %}
    - contents_pillar: {{ file.contents_pillar }}
    {%- elif file.contents_grains is defined %}
    - contents_grains: {{ file.contents_grains }}
    {%- endif %}
{%- endif %}
    {%- if file.dir_mode is defined %}
    - dir_mode: {{ file.dir_mode }}
    {%- endif %}
    {%- if file.encoding is defined %}
    - encoding: {{ file.encoding }}
    {%- endif %}
{%- endif %}
    - makedirs: {{ file.get('makedirs', 'True') }}
    - user: {{ file.get('user', 'root') }}
    - group: {{ file.get('group', 'root') }}
    {%- if file.mode is defined %}
    - mode: {{ file.mode }}
    {%- endif %}
    - require:
      - file: {{ service.tftproot }}
{%- endfor %}
{{ service.etc }}/chroots/{{ chroot }}:
  file.directory:
    - makedirs: True
    - clean: True
{{ service.etc }}/chroots/{{ chroot }}/ltsp-build-client.conf:
  file.managed:
    - source: salt://ltsp/files/ltsp-build-client.conf
    - template: jinja
    - context:
        chroot: {{ chroot }}
    - makedirs: True
    - require_in:
      - file: {{ service.etc }}/chroots/{{ chroot }}
{%- for key, keycfg in chrootcfg.get('_keys', {}).items() %}
{{ service.etc }}/chroots/{{ chroot }}/{{ key }}:
  file.managed:
    - source: {{ keycfg.url }}
    - source_hash: {{ keycfg.hash }}
    - makedirs: True
    - require_in:
      - file: {{ service.etc }}/chroots/{{ chroot }}
gpg_import_key_{{ service.etc }}/chroots/{{ chroot }}/{{ key }}:
  module.run:
    - name: gpg.import_key
    - kwargs:
        filename: {{ service.etc }}/chroots/{{ chroot }}/{{ key }}
    - require_in:
      - cmd: ltsp-build-client_{{ chroot }}
    - require:
      - file: {{ service.etc }}/chroots/{{ chroot }}/{{ key }}
      - pkg: ltsp_pkgs
    - onchanges:
      - file: {{ service.etc }}/chroots/{{ chroot }}/{{ key }}
{%- endfor %}
ltsp-build-client_{{ chroot }}:
  cmd.run:
    - name: /usr/sbin/ltsp-build-client --purge-chroot --config {{ service.etc }}/chroots/{{ chroot }}/ltsp-build-client.conf
    - creates: {{ service.chroot[chroot]._path }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - require:
      - file: {{ service.etc }}/chroots/{{ chroot }}
    - watch_in:
      - service: nbd-server
{%- endif %}
{%- endfor %}
/usr/local/bin/ltsp_dnsmasq.sh:
  file.managed:
    - source: salt://ltsp/files/ltsp_dnsmasq.sh
    - template: jinja
    - mode: 755
    - makedirs: True
    - require:
      - file: {{ service.tftproot }}

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

dnsmasq:
  service.dead:
    - enable: False

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
    - require:
      - service: dnsmasq
{%- else %}
  service.dead:
    - enable: False
    - require:
      - file: /etc/systemd/system/ltsp.service
{%- endif %}

nbd-server:
{%- if service.running %}
  {%- if grains.get('noservices') %}
  service.enabled:
    - unless: /bin/true
  {%- else %}
  service.running:
    - enable: True
  {%- endif %}
    - watch:
      - pkg: ltsp_pkgs
{%- else %}
  service.dead:
    - enable: False
{%- endif %}

{%- endif %}
