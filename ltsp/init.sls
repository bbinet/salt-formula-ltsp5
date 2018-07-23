{%- if pillar.ltsp is defined %}
include:
{%- if pillar.ltsp.service is defined %}
- ltsp.service
{%- endif %}
{%- endif %}
