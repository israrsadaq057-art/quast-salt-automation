# /srv/salt/quast/orchestration/compliance_check.sls
# Network Compliance Check Orchestration
# Network Engineer: Israr Sadaq
#
# Checks that ALL devices follow security standards
#
# RUN WITH: sudo salt-run state.orchestrate quast.orchestration.compliance_check

# ============================================================
# CHECK NTP CONFIGURATION
# ============================================================
check_ntp_compliance:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-core-*'
    - arg:
      - |
        echo "=== Checking NTP on {{ grains.id }} ==="
        show ntp associations | grep -q "0.asia.pool.ntp.org"
        if [ $? -ne 0 ]; then
          echo "FAIL: NTP not configured correctly"
          exit 1
        fi
        echo "PASS: NTP is correct"

# ============================================================
# CHECK SNMP CONFIGURATION
# ============================================================
check_snmp_compliance:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-core-*'
    - arg:
      - |
        echo "=== Checking SNMP on {{ grains.id }} ==="
        show snmp | grep -q "monitoring"
        if [ $? -ne 0 ]; then
          echo "FAIL: SNMP community not found"
          exit 1
        fi
        echo "PASS: SNMP is correct"

# ============================================================
# CHECK SSH CONFIGURATION
# ============================================================
check_ssh_compliance:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-core-*'
    - arg:
      - |
        echo "=== Checking SSH on {{ grains.id }} ==="
        show ip ssh | grep -q "version 2"
        if [ $? -ne 0 ]; then
          echo "FAIL: SSH version 2 not enabled"
          exit 1
        fi
        echo "PASS: SSH is correct"

# ============================================================
# CHECK VLAN CONFIGURATION
# ============================================================
check_vlan_compliance:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-dist-*'
    - arg:
      - |
        echo "=== Checking VLANs on {{ grains.id }} ==="
        show vlan id 10 | grep -q "MGMT"
        if [ $? -ne 0 ]; then
          echo "FAIL: VLAN 10 not found"
          exit 1
        fi
        echo "PASS: VLAN configuration is correct"

# ============================================================
# GENERATE COMPLIANCE REPORT
# ============================================================
generate_report:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-mon-01'
    - arg:
      - |
        echo "=========================================="
        echo "QUAST UNIVERSITY - COMPLIANCE REPORT"
        echo "Date: $(date)"
        echo "=========================================="
        echo ""
        echo "NTP Compliance: $(salt 'quast-core-*' cmd.run 'show ntp associations | grep pool' | wc -l)/$(salt 'quast-core-*' test.ping | grep True | wc -l) passed"
        echo "SNMP Compliance: $(salt 'quast-core-*' cmd.run 'show snmp | grep monitoring' | wc -l)/$(salt 'quast-core-*' test.ping | grep True | wc -l) passed"
        echo "SSH Compliance: $(salt 'quast-core-*' cmd.run 'show ip ssh | grep version' | wc -l)/$(salt 'quast-core-*' test.ping | grep True | wc -l) passed"
        echo "VLAN Compliance: $(salt 'quast-dist-*' cmd.run 'show vlan id 10' | grep MGMT | wc -l)/$(salt 'quast-dist-*' test.ping | grep True | wc -l) passed"
        echo ""
        echo "=========================================="
