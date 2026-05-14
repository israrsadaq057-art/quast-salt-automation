# /srv/salt/quast/orchestration/full_deploy.sls
# QUAST University - Complete Network Deployment Orchestration
# Network Engineer: Israr Sadaq
#
# This orchestration runs states in the CORRECT order
# Each step waits for previous step to complete
#
# RUN WITH: sudo salt-run state.orchestrate quast.orchestration.full_deploy

# ============================================================
# STAGE 1: DEPLOY CORE SWITCHES
# ============================================================
# Core switches must be FIRST because everything connects to them
# This includes: VPC, VLANs, routing, global services

deploy_core_switches:
  salt.state:
    - tgt: 'quast-core-*'
    - sls:
      - quast.network.core.vlans
      - quast.network.core.global_services
      - quast.network.core.vpc
      - quast.network.core.routing
    - batch: 1                    # Deploy one core switch at a time
    - failhard: True              # Stop if any core switch fails
    - require:
      - salt: refresh_pillar

# ============================================================
# STAGE 2: WAIT FOR CORE STABILITY
# ============================================================
# Give core switches time to establish VPC and OSPF neighbors

wait_for_core:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-core-01'
    - arg:
      - sleep 30 && echo "Core stable"
    - require:
      - salt: deploy_core_switches

# ============================================================
# STAGE 3: VERIFY CORE IS READY
# ============================================================
# Check VPC status and OSPF neighbors before proceeding

verify_core_ready:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-core-01'
    - arg:
      - |
        echo "=== Checking VPC Status ==="
        show vpc | grep -q "peer adjacency formed ok"
        if [ $? -ne 0 ]; then
          echo "ERROR: VPC peer not formed"
          exit 1
        fi
        echo "=== VPC is healthy ==="
    - require:
      - salt: wait_for_core

# ============================================================
# STAGE 4: DEPLOY DISTRIBUTION SWITCHES
# ============================================================
# Distribution switches need core to be ready for uplinks

deploy_distribution_switches:
  salt.state:
    - tgt: 'quast-dist-*'
    - sls:
      - quast.network.distribution.base
    - batch: 2                    # Deploy 2 distribution switches at a time
    - failhard: True
    - require:
      - salt: verify_core_ready

# ============================================================
# STAGE 5: VERIFY DISTRIBUTION UPLINKS
# ============================================================
# Check that all distribution switches can reach core

verify_distribution_uplinks:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-dist-cs'
    - arg:
      - |
        echo "=== Testing uplink to core ==="
        ping 10.10.10.1 -c 3 | grep -q "0% packet loss"
        if [ $? -ne 0 ]; then
          echo "ERROR: Cannot reach core switch"
          exit 1
        fi
        echo "=== Uplink to core is working ==="
    - require:
      - salt: deploy_distribution_switches

# ============================================================
# STAGE 6: DEPLOY ACCESS SWITCHES (IN BATCHES)
# ============================================================
# 250 access switches - deploy in batches of 10
# Too many at once could overwhelm the network

deploy_access_switches:
  salt.state:
    - tgt: 'quast-acc-*'
    - sls:
      - quast.network.access.base
    - batch: 10                   # 10 switches at a time
    - failhard: False             # Don't stop if one access switch fails
    - require:
      - salt: verify_distribution_uplinks

# ============================================================
# STAGE 7: VERIFY ACCESS SWITCHES
# ============================================================
# Sample check on a few access switches

verify_access_switches:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-acc-cs-lab1'
    - arg:
      - |
        echo "=== Checking uplink status ==="
        show interface GigabitEthernet1/0/48 | grep -q "up"
        if [ $? -ne 0 ]; then
          echo "ERROR: Uplink is down"
          exit 1
        fi
        echo "=== Access switch is online ==="
    - require:
      - salt: deploy_access_switches

# ============================================================
# STAGE 8: DEPLOY FIREWALLS
# ============================================================
# Firewalls need network to be ready before testing

deploy_firewalls:
  salt.state:
    - tgt: 'quast-fw-*'
    - sls:
      - quast.security.firewall.ha
      - quast.security.firewall.policies
    - batch: 1
    - failhard: True
    - require:
      - salt: verify_access_switches

# ============================================================
# STAGE 9: VERIFY FIREWALL
# ============================================================

verify_firewall_ha:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-fw-pri'
    - arg:
      - |
        echo "=== Checking HA status ==="
        get system ha status | grep -q "Primary"
        if [ $? -ne 0 ]; then
          echo "ERROR: Firewall HA not working"
          exit 1
        fi
        echo "=== Firewall HA is healthy ==="
    - require:
      - salt: deploy_firewalls

# ============================================================
# STAGE 10: DEPLOY WIRELESS
# ============================================================

deploy_wireless:
  salt.state:
    - tgt: 'quast-wlc-*'
    - sls:
      - quast.network.wireless.controller
      - quast.network.wireless.ssids
    - batch: 1
    - failhard: True
    - require:
      - salt: verify_firewall_ha

# ============================================================
# STAGE 11: DEPLOY ACCESS POINTS
# ============================================================
# APs deploy after controller is ready

deploy_access_points:
  salt.state:
    - tgt: 'quast-wlc-01'
    - sls:
      - quast.network.wireless.access_points
    - require:
      - salt: deploy_wireless

# ============================================================
# STAGE 12: DEPLOY MONITORING
# ============================================================
# Monitoring is LAST - it needs to discover all devices

deploy_monitoring:
  salt.state:
    - tgt: 'quast-mon-*'
    - sls:
      - quast.monitoring.icinga2.server
      - quast.monitoring.icinga2.network_hosts
      - quast.monitoring.icinga2.service_checks
    - batch: 1
    - require:
      - salt: deploy_access_points

# ============================================================
# STAGE 13: FINAL VERIFICATION
# ============================================================
# Full network health check

final_verification:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-mon-01'
    - arg:
      - |
        echo "=========================================="
        echo "QUAST UNIVERSITY - DEPLOYMENT COMPLETE"
        echo "=========================================="
        echo ""
        echo "=== Core Switches ==="
        echo "Core-01: $(salt 'quast-core-01' cmd.run 'show version | head -1')"
        echo "Core-02: $(salt 'quast-core-02' cmd.run 'show version | head -1')"
        echo ""
        echo "=== Distribution Switches ==="
        echo "Total: $(salt 'quast-dist-*' test.ping | grep True | wc -l)"
        echo ""
        echo "=== Access Switches ==="
        echo "Total: $(salt 'quast-acc-*' test.ping | grep True | wc -l)"
        echo ""
        echo "=== Firewall ==="
        salt 'quast-fw-pri' cmd.run 'get system ha status | grep -E "Priority|State"'
        echo ""
        echo "=== Wireless ==="
        echo "APs Joined: $(salt 'quast-wlc-01' cmd.run 'show ap summary | grep Registered | wc -l')"
        echo ""
        echo "=== Monitoring ==="
        echo "Hosts in Icinga: $(salt 'quast-mon-01' cmd.run 'icinga2 console --connect "get objects" | grep Host | wc -l')"
        echo ""
        echo "=========================================="
        echo "DEPLOYMENT SUCCESSFUL!"
        echo "=========================================="
    - require:
      - salt: deploy_monitoring
