# /srv/salt/quast/orchestration/backup_configs.sls
# Automatic Configuration Backup Orchestration
# Network Engineer: Israr Sadaq
#
# Runs daily to backup ALL device configurations
#
# SCHEDULE: Daily at 2:00 AM
# RUN WITH: sudo salt-run state.orchestrate quast.orchestration.backup_configs

# ============================================================
# BACKUP CORE SWITCHES
# ============================================================
backup_core:
  salt.function:
    - name: net.save_config
    - tgt: 'quast-core-*'
    - arg:
      - path: "/backup/{{ grains.id }}/{{ salt.cmd.run('date +%Y%m%d') }}/running-config.txt"
    - require:
      - salt: create_backup_dir

# ============================================================
# BACKUP DISTRIBUTION SWITCHES
# ============================================================
backup_distribution:
  salt.function:
    - name: net.save_config
    - tgt: 'quast-dist-*'
    - arg:
      - path: "/backup/{{ grains.id }}/{{ salt.cmd.run('date +%Y%m%d') }}/running-config.txt"
    - require:
      - salt: backup_core

# ============================================================
# BACKUP ACCESS SWITCHES (Batch of 20)
# ============================================================
backup_access:
  salt.function:
    - name: net.save_config
    - tgt: 'quast-acc-*'
    - arg:
      - path: "/backup/{{ grains.id }}/{{ salt.cmd.run('date +%Y%m%d') }}/running-config.txt"
    - batch: 20
    - require:
      - salt: backup_distribution

# ============================================================
# BACKUP FIREWALLS
# ============================================================
backup_firewall:
  salt.function:
    - name: net.save_config
    - tgt: 'quast-fw-*'
    - arg:
      - path: "/backup/{{ grains.id }}/{{ salt.cmd.run('date +%Y%m%d') }}/config.conf"
    - require:
      - salt: backup_access

# ============================================================
# BACKUP WIRELESS CONTROLLER
# ============================================================
backup_wlc:
  salt.function:
    - name: net.save_config
    - tgt: 'quast-wlc-01'
    - arg:
      - path: "/backup/{{ grains.id }}/{{ salt.cmd.run('date +%Y%m%d') }}/wlc_config.txt"
    - require:
      - salt: backup_firewall

# ============================================================
# UPLOAD TO GIT REPOSITORY (Version Control)
# ============================================================
upload_to_git:
  salt.function:
    - name: cmd.run
    - tgt: 'quast-backup-01'
    - arg:
      - |
        cd /backup
        git add .
        git commit -m "Daily backup $(date +%Y%m%d)"
        git push origin main
    - require:
      - salt: backup_wlc
