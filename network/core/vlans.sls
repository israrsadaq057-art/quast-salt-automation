# /srv/salt/quast/network/core/vlans.sls
# Core Switch VLAN Configuration
# Network Engineer: Israr Sadaq
# Date: May 2026
#
# This state configures VLANs on core switches
# It uses data from: /srv/pillar/quast/network/global/vlans.sls

# ============================================================
# STEP 1: Configure Infrastructure VLANs
# ============================================================
# This uses a Jinja2 template to generate Cisco CLI
# The template will be created in the next step

configure_infrastructure_vlans:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/vlans.j2
    - template_args:
        context:
          vlans: {{ pillar.get('infrastructure_vlans', {}) | json }}
          vlan_type: "infrastructure"
    - debug: false
    - commit_config: true
    - replace: false
    - save_config: true

# ============================================================
# STEP 2: Configure Academic VLANs
# ============================================================
configure_academic_vlans:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/vlans.j2
    - template_args:
        context:
          vlans: {{ pillar.get('academic_vlans', {}) | json }}
          vlan_type: "academic"
    - commit_config: true
    - require:
      - napalm_managed: configure_infrastructure_vlans

# ============================================================
# STEP 3: Configure Research VLANs
# ============================================================
configure_research_vlans:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/vlans.j2
    - template_args:
        context:
          vlans: {{ pillar.get('research_vlans', {}) | json }}
          vlan_type: "research"
    - commit_config: true
    - require:
      - napalm_managed: configure_academic_vlans

# ============================================================
# STEP 4: Configure Residence VLANs
# ============================================================
configure_residence_vlans:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/vlans.j2
    - template_args:
        context:
          vlans: {{ pillar.get('residence_vlans', {}) | json }}
          vlan_type: "residence"
    - commit_config: true
    - require:
      - napalm_managed: configure_research_vlans

# ============================================================
# STEP 5: Configure Data Center VLANs
# ============================================================
configure_datacenter_vlans:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: ios
    - template: salt://quast/templates/cisco/vlans.j2
    - template_args:
        context:
          vlans: {{ pillar.get('datacenter_vlans', {}) | json }}
          vlan_type: "datacenter"
    - commit_config: true
    - require:
      - napalm_managed: configure_residence_vlans

# ============================================================
# STEP 6: Verify VLAN configuration
# ============================================================
verify_vlans:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - function: get_vlans
    - output_file: /var/log/salt/vlans_{{ grains.id }}.log
    - require:
      - napalm_managed: configure_datacenter_vlans
