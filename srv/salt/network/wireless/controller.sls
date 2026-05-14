# /srv/salt/quast/network/wireless/controller.sls
# Cisco 9800-80 Wireless Controller Configuration
# Network Engineer: Israr Sadaq
#
# This state configures:
# - WLC hostname, management IP
# - AP Manager interface
# - Virtual IP for anchor
# - RF profiles
#
# Data source: /srv/pillar/quast/network/wireless/controller.sls

# ============================================================
# SECTION 1: Controller Specific Data
# ============================================================
{% set wlc = pillar.get('wireless_controller', {}).get(grains.id, {}) %}
{% set interfaces = pillar.get('wlc_interfaces', {}) %}
{% set rf_profiles = pillar.get('rf_profiles', {}) %}

# ============================================================
# SECTION 2: Hostname and Management
# ============================================================
configure_wlc_hostname:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/hostname.j2
    - template_args:
        context:
          hostname: {{ grains.id }}
          mgmt_ip: {{ wlc.get('mgmt_ip') }}
          ap_manager_ip: {{ wlc.get('ap_manager_ip') }}
          virtual_ip: {{ wlc.get('virtual_ip', '10.10.41.254') }}
    - commit_config: true
    - save_config: true

# ============================================================
# SECTION 3: Configure Interfaces
# ============================================================
configure_wlc_interfaces:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/interfaces.j2
    - template_args:
        context:
          interfaces: {{ interfaces | json }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_wlc_hostname

# ============================================================
# SECTION 4: Configure RF Profiles (Radio Frequency)
# ============================================================
# RF profiles control power and channel settings
# Different profiles for different areas (high density, outdoor, etc.)

configure_rf_profiles:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/rf_profiles.j2
    - template_args:
        context:
          rf_profiles: {{ rf_profiles | json }}
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_wlc_interfaces

# ============================================================
# SECTION 5: Configure FlexConnect Groups
# ============================================================
# FlexConnect allows APs to switch traffic locally
# Used for remote campuses (Engineering, Medical)

configure_flexconnect_groups:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/wireless/flexconnect.j2
    - template_args:
        context:
          flex_groups:
            - name: MAIN-CAMPUS
              central_switching: true
            - name: ENGINEERING
              central_switching: false
              local_vlan: [100,200,300]
            - name: MEDICAL
              central_switching: false
              local_vlan: [100,200,300]
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_rf_profiles
