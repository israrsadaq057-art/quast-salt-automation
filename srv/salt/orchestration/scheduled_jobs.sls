# /srv/salt/quast/orchestration/scheduled_jobs.sls
# Scheduled Automation Jobs
# Network Engineer: Israr Sadaq

# ============================================================
# DAILY BACKUP (2:00 AM)
# ============================================================
schedule_daily_backup:
  schedule.present:
    - name: daily_config_backup
    - function: state.orchestrate
    - args:
      - quast.orchestration.backup_configs
    - when:
      - 2:00
    - splay: 1800
    - range:
        - start: 2026-05-15T00:00:00
        - end: 2026-12-31T23:59:00

# ============================================================
# WEEKLY COMPLIANCE CHECK (Sunday 3:00 AM)
# ============================================================
schedule_weekly_compliance:
  schedule.present:
    - name: weekly_compliance
    - function: state.orchestrate
    - args:
      - quast.orchestration.compliance_check
    - when:
      - 3:00
    - weekday: 7
    - splay: 3600

# ============================================================
# MONTHLY SOFTWARE UPDATE (First Saturday 4:00 AM)
# ============================================================
schedule_monthly_updates:
  schedule.present:
    - name: monthly_firmware_check
    - function: state.orchestrate
    - args:
      - quast.orchestration.software_updates
    - when:
      - 4:00
    - day: 1
    - splay: 7200

# ============================================================
# REALTIME MONITORING (Every 5 minutes)
# ============================================================
schedule_device_health:
  schedule.present:
    - name: device_health_check
    - function: salt.function
    - args:
      - cmd.run
      - "show processes cpu | include CPU"
    - tgt: 'quast-core-*'
    - minutes: 5
