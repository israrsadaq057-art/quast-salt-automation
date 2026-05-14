# /srv/salt/quast/network/wireless/access_points.sls
# Access Point Configuration
# Network Engineer: Israr Sadaq
#
# This state configures APs to join the WLC
# APs automatically download config from controller

# ============================================================
# SECTION 1: AP Authorization
# ============================================================
# Only authorized APs can join the WLC
# Based on MAC address or serial number

{% set authorized_aps = pillar.get('access_points', []) %}

authorize_access_points:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/ap_auth.j2
    - template_args:
        context:
          ap_list: {{ authorized_aps | json }}
    - commit_config: true
    - save_config: true

# ============================================================
# SECTION 2: AP Groups (By Building)
# ============================================================
# Group APs by location for easier management

configure_ap_groups:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/ap_groups.j2
    - template_args:
        context:
          ap_groups:
            - name: CS-BUILDING
              description: "Computer Science Building"
              ssid: [FACULTY, STUDENTS, RESEARCH]
            - name: LIBRARY
              description: "Central Library"
              ssid: [FACULTY, STUDENTS, GUEST]
            - name: HOSTELS
              description: "Student Hostels"
              ssid: [STUDENTS, GUEST]
            - name: ENGINEERING
              description: "Engineering Campus"
              ssid: [FACULTY, STUDENTS]
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: authorize_access_points

# ============================================================
# SECTION 3: AP Join Configuration
# ============================================================
# Default settings for new APs

configure_ap_join:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/ap_join.j2
    - template_args:
        context:
          country: PK
          timezone: "Asia/Karachi"
          led_state: true
          syslog: 10.10.40.50
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_ap_groups
