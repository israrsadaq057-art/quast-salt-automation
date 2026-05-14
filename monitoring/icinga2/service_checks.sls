# /srv/salt/quast/monitoring/icinga2/service_checks.sls
# Service Check Definitions
# Network Engineer: Israr Sadaq

configure_service_checks:
  file.managed:
    - name: /etc/icinga2/conf.d/services/network_services.conf
    - source: salt://quast/templates/icinga2/service_checks.conf
    - template: jinja
    - context:
        ntp_servers: {{ pillar.get('ntp:servers', []) }}
        dns_servers: {{ pillar.get('dns:servers', []) }}
        radius_servers: 
          - {{ pillar.get('aaa:primary_server') }}
          - {{ pillar.get('aaa:secondary_server') }}
        syslog_servers: {{ pillar.get('syslog:servers', []) }}
    - require:
      - service: start_icinga2

configure_notifications:
  file.managed:
    - name: /etc/icinga2/conf.d/notifications.conf
    - contents: |
        // ============================================
        // NOTIFICATION CONFIGURATION
        // Alerts via Email and Webhook
        // ============================================
        
        object User "netadmin" {
          import "generic-user"
          display_name = "Network Admin Team"
          email = "netadmin@quast.edu.pk"
        }
        
        object NotificationCommand "mail-service-notification" {
          import "plugin-notification"
          command = [ ConfigDir + "/scripts/mail-service-notification.sh" ]
          
          arguments = {
            "-e" = {
              value = "$service.state$ $service.state_type$"
            }
            "-r" = {
              value = "$service.output$"
            }
          }
        }
        
        apply Notification "email-notification" to Service {
          import "mail-service-notification"
          users = ["netadmin"]
          assign where host.vars.notification == true
        }
