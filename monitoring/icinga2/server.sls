# /srv/salt/quast/monitoring/icinga2/server.sls
# Icinga2 Master Server Installation
# Network Engineer: Israr Sadaq
#
# This state installs and configures Icinga2 master
# Monitors ALL network devices, servers, and services

# ============================================================
# SECTION 1: Add Icinga2 Repository
# ============================================================
add_icinga_repo:
  file.managed:
    - name: /etc/apt/sources.list.d/icinga2.list
    - contents: |
        deb https://packages.icinga.com/ubuntu icinga-$(lsb_release -sc) main
    - mode: 644

add_icinga_key:
  cmd.run:
    - name: |
        wget -O - https://packages.icinga.com/icinga.key | apt-key add -
    - unless: apt-key list | grep -q "Icinga"

# ============================================================
# SECTION 2: Install Icinga2 and Dependencies
# ============================================================
install_icinga2:
  pkg.installed:
    - pkgs:
      - icinga2
      - icinga2-ido-mysql
      - monitoring-plugins
      - nagios-plugins-contrib
      - snmp
      - snmp-mibs-downloader
      - snmpd
      - sendmail
      - mariadb-server
      - mariadb-client
      - php7.4
      - php7.4-fpm
      - php7.4-cli
      - nginx
    - refresh: true
    - require:
      - cmd: add_icinga_key

# ============================================================
# SECTION 3: Configure MySQL Database
# ============================================================
configure_mysql:
  service.running:
    - name: mysql
    - enable: true

create_icinga_db:
  cmd.run:
    - name: |
        mysql -e "CREATE DATABASE IF NOT EXISTS icinga2;"
        mysql -e "CREATE USER IF NOT EXISTS 'icinga2'@'localhost' IDENTIFIED BY '{{ pillar['secrets']['icinga_db_pass'] }}';"
        mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON icinga2.* TO 'icinga2'@'localhost';"
        mysql -e "FLUSH PRIVILEGES;"
    - unless: mysql -e "USE icinga2"
    - require:
      - service: configure_mysql

load_icinga_schema:
  cmd.run:
    - name: |
        mysql -u root icinga2 < /usr/share/icinga2-ido-mysql/schema/mysql.sql
    - unless: mysql -e "USE icinga2; SHOW TABLES" | grep -q "icinga_dbversion"
    - require:
      - cmd: create_icinga_db

# ============================================================
# SECTION 4: Configure Icinga2 Master
# ============================================================
configure_icinga_master:
  file.managed:
    - name: /etc/icinga2/features-enabled/ido-mysql.conf
    - source: salt://quast/templates/icinga2/ido-mysql.conf
    - template: jinja
    - context:
        db_pass: {{ pillar['secrets']['icinga_db_pass'] }}
    - require:
      - pkg: install_icinga2

enable_features:
  cmd.run:
    - names:
      - icinga2 feature enable ido-mysql
      - icinga2 feature enable api
      - icinga2 feature enable notification
      - icinga2 feature enable graphite
      - icinga2 feature enable command
    - unless: icinga2 feature list | grep -q "Enabled: ido-mysql"

# ============================================================
# SECTION 5: Configure API for Salt Integration
# ============================================================
configure_api:
  file.managed:
    - name: /etc/icinga2/features-enabled/api.conf
    - source: salt://quast/templates/icinga2/api.conf
    - template: jinja
    - context:
        api_user: {{ pillar.get('icinga_api_user', 'salt') }}
        api_pass: {{ pillar['secrets']['icinga_api_pass'] }}
    - require:
      - cmd: enable_features

# ============================================================
# SECTION 6: Configure Graphite Integration
# ============================================================
configure_graphite:
  file.managed:
    - name: /etc/icinga2/features-enabled/graphite.conf
    - source: salt://quast/templates/icinga2/graphite.conf
    - context:
        graphite_host: 10.10.40.60
        graphite_port: 2003
    - require:
      - cmd: enable_features

# ============================================================
# SECTION 7: Start Icinga2
# ============================================================
start_icinga2:
  service.running:
    - name: icinga2
    - enable: true
    - watch:
      - file: configure_icinga_master
      - file: configure_api
