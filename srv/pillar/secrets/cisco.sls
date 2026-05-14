# /srv/pillar/quast/secrets/cisco.sls
# Cisco Device Secrets
# WARNING: In production, encrypt this file with GPG!

secrets:
  cisco_username: "netadmin"
  cisco_password: "Cisco123!"
  radius_key: "R@d1uS_K3y_2026"
  local_backup_password: "BackupPass456"
  snmp_auth_netadmin: "SnmpAuthPass789"
  snmp_priv_netadmin: "SnmpPrivPass789"
