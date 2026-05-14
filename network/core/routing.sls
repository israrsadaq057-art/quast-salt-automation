# /srv/salt/quast/network/core/routing.sls
# Core Switch Routing Configuration (OSPF + BGP)
# Network Engineer: Israr Sadaq
# Date: May 2026
#
# This state configures:
# - OSPF for internal routing between campus switches
# - BGP for ISP connectivity (PTCL + Transworld)
# - Static routes for management
# - Route redistribution
#
# Data source: /srv/pillar/quast/network/core/switches.sls
#              /srv/pillar/quast/network/wan/bgp.sls

# ============================================================
# SECTION 1: OSPF (Open Shortest Path First)
# ============================================================
# OSPF learns routes from all distribution switches
# Automatically finds best path if a link fails

{% set ospf = pillar.get('ospf', {}) %}
{% set core_switches = pillar.get('core_switches', {}) %}
{% set this_switch = core_switches.get(grains.id|replace('quast-', ''), {}) %}

configure_ospf:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: nxos
    - template: salt://quast/templates/cisco/ospf.j2
    - template_args:
        context:
          process_id: {{ ospf.get('process_id', 10) }}
          router_id: {{ ospf.get('router_id', '10.10.10.1') }}
          networks: {{ ospf.get('networks', []) | json }}
          passive_interfaces: {{ ospf.get('passive_interfaces', []) | json }}
          redistribute: ["connected", "static"]
    - commit_config: true
    - save_config: true

# ============================================================
# SECTION 2: OSPF INTERFACE PARAMETERS
# ============================================================
# Tune OSPF on specific interfaces
# Faster convergence, better security

configure_ospf_interfaces:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: nxos
    - template: salt://quast/templates/cisco/ospf_interfaces.j2
    - template_args:
        context:
          uplink_interfaces:
            - name: port-channel100
              ospf_cost: 10
              ospf_priority: 1
            - name: port-channel101
              ospf_cost: 10
              ospf_priority: 1
          network_type: point-to-point
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_ospf

# ============================================================
# SECTION 3: OSPF AUTHENTICATION (MD5)
# ============================================================
# Prevents rogue switches from joining OSPF
# All switches must share the same password

configure_ospf_auth:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: nxos
    - template: salt://quast/templates/cisco/ospf_auth.j2
    - template_args:
        context:
          auth_key: {{ pillar['secrets']['ospf_auth_key'] }}
          auth_key_id: 1
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_ospf_interfaces

# ============================================================
# SECTION 4: BGP FOR ISP CONNECTIVITY
# ============================================================
# Only configure BGP on the primary core switch
# BGP peers with PTCL and Transworld ISPs

{% if this_switch.get('vpc_role') == 'primary' %}
configure_bgp:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: nxos
    - template: salt://quast/templates/cisco/bgp.j2
    - template_args:
        context:
          as_number: 65001
          router_id: {{ ospf.get('router_id', '10.10.10.1') }}
          bgp_neighbors:
            - name: PTCL
              ip: 203.124.10.1
              remote_as: 17557
              password: {{ pillar['secrets']['bgp_ptcl_password'] }}
              keepalive: 30
              holdtime: 90
              description: "PTCL ISP Link"
            - name: TRANSWORLD
              ip: 203.124.11.1
              remote_as: 38710
              password: {{ pillar['secrets']['bgp_tworld_password'] }}
              keepalive: 30
              holdtime: 90
              description: "Transworld ISP Link"
          networks_to_advertise:
            - 203.124.0.0/19
            - 10.0.0.0/8
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_ospf_auth
{% endif %}

# ============================================================
# SECTION 5: STATIC ROUTES
# ============================================================
# Default route to firewall
# Management routes

configure_static_routes:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: nxos
    - template: salt://quast/templates/cisco/static_routes.j2
    - template_args:
        context:
          static_routes:
            - dest: 0.0.0.0
              mask: 0.0.0.0
              next_hop: 10.10.0.1
              name: "Default to Firewall"
            - dest: 10.10.40.0
              mask: 255.255.255.0
              next_hop: 10.10.10.254
              name: "Management Network"
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_ospf_auth

# ============================================================
# SECTION 6: ROUTE REDISTRIBUTION
# ============================================================
# Share routes between OSPF and BGP
# So internal switches know about internet routes

configure_route_redistribution:
  napalm_managed:
    - hostname: {{ grains.id }}
    - username: {{ pillar['secrets']['cisco_username'] }}
    - password: {{ pillar['secrets']['cisco_password'] }}
    - dev_os: nxos
    - template: salt://quast/templates/cisco/route_redist.j2
    - template_args:
        context:
          redistribute:
            - from: bgp
              to: ospf
              metric: 100
              route_map: "BGP_TO_OSPF"
            - from: static
              to: ospf
              metric: 110
    - commit_config: true
    - save_config: true
    - require:
      - napalm_managed: configure_bgp
      - napalm_managed: configure_ospf

# ============================================================
# SECTION 7: VERIFY ROUTING
# ============================================================
# Check OSPF neighbors and BGP peers

verify_routing:
  cmd.run:
    - name: |
        echo "=== OSPF Neighbors ==="
        show ip ospf neighbors
        echo ""
        echo "=== OSPF Routes ==="
        show ip route ospf
        echo ""
        echo "=== BGP Summary ==="
        show bgp summary
        echo ""
        echo "=== BGP Routes ==="
        show bgp neighbors
    - shell: /bin/bash
    - runas: root
    - require:
      - napalm_managed: configure_route_redistribution
