{% set solr_url= salt['pillar.get']('solrcloud:solr_url', "http://www.eu.apache.org/dist/lucene/solr/") %}
{% set solr_ver= salt['pillar.get']('solrcloud:solr_ver', "5.5.0") %}
{% set solr_name= salt['pillar.get']('solrcloud:solr_name', "solr") %}
{% set solr_logs= salt['pillar.get']('solrcloud:solr_logs', "/var/solr/logs/") %}
{% set solr_data= salt['pillar.get']('solrcloud:solr_data', "/var/solr/data/") %}
{% set solr_home= salt['pillar.get']('solrcloud:solr_home', "/var/solr/") %}
{% set solr_user= salt['pillar.get']('solrcloud:solr_user', "solr") %}
{% set solr_install_dir= salt['pillar.get']('solrcloud:solr_install_dir', "/opt/solr") %}

{% set zoo_data= salt['pillar.get']('solrcloud:zoo_data', "/var/zookeeper/data") %}
{% set zoo_logs= salt['pillar.get']('solrcloud:zoo_logs', "/var/zookeeper/logs") %}

solr_data_disk:
  mount.mounted:
    - name: {{solr_data}}
    - device: /dev/xvdb1
    - mkmnt: True
    - fstype: ext4
solr_logs_disk:
  mount.mounted:
    - name: {{solr_logs}}
    - device: /dev/xvdc1
    - mkmnt: True
    - fstype: ext4
zk_data_disk:
  mount.mounted:
    - name: {{zoo_data}}
    - device: /dev/xvde1
    - mkmnt: True
    - fstype: ext4
zk_logs_disk:
  mount.mounted:
    - name: {{zoo_logs}}
    - device: /dev/xvdf1
    - mkmnt: True
    - fstype: ext4

lsof:
  pkg.installed

solr:
  archive.extracted:
    - name: /opt/
    - source: {{solr_url}}{{solr_ver}}/{{solr_name}}-{{solr_ver}}.tgz
    - source_hash: {{solr_url}}{{solr_ver}}/{{solr_name}}-{{solr_ver}}.tgz.md5
    - archive_format: tar
    - user: root
    - if_missing: /opt/{{solr_name}}-{{solr_ver}}/
  file.symlink:
    - name: {{solr_install_dir}}
    - target: /opt/{{solr_name}}-{{solr_ver}}/

solr_user:
  user.present:
    - name: {{solr_user}}
    - home: {{solr_home}}
    - system: True
    - shell: /bin/bash

{% set dir_list = [solr_home,solr_logs,solr_data] %}
{% for dir in dir_list %}
{{dir}}:
  file.directory:
    - user: {{solr_user}}
    - group: {{solr_user}}
    - dir_mode: 0755
    - file_mode: 0644
    - recurse:
      - user
      - mode
    - makedirs: True
{% endfor %}

solr_init_file:
  file.managed:
    - name: /etc/init.d/{{solr_name}}
    - source: salt://solrcloud/files/solr
    - template: jinja
    - user: root
    - mode: 0755

solr_include_file:
  file.managed:
    - name: /etc/default/solr.in.sh
    - source: salt://solrcloud/files/solr.in.sh
    - template: jinja
    - user: root
    - mode: 0644

solr_xml:
  file.managed:
    - name: {{solr_data}}solr.xml
    - source: salt://solrcloud/files/solr.xml
    - template: jinja
    - user: {{solr_user}}
    - group: {{solr_user}}
    - mode: 0644

solr_log4j:
  file.managed:
    - name: {{solr_home}}log4j.properties
    - source: salt://solrcloud/files/log4j.properties
    - template: jinja
    - user: {{solr_user}}
    - group: {{solr_user}}
    - mode: 0644

solr_service:
  service.running:
    - name: {{solr_name}}
    - enable: True
    - provider: service
    - reload: True
    - watch:
      - file: {{solr_data}}solr.xml
      - file: {{solr_home}}log4j.properties
