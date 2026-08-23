#!/bin/bash
# Nagios notification command — pages Hermes agent via Trentina alert ingress.
# Called by Nagios for both service and host notifications.
# TRENTINA_ALERT_URL must be set in the container environment.

/usr/bin/curl -s -X POST "${TRENTINA_ALERT_URL}" \
  -H "Content-Type: application/json" \
  -d "{\"host\":\"${NAGIOS_HOSTNAME}\",\"service\":\"${NAGIOS_SERVICEDESC:-host}\",\"state\":\"${NAGIOS_SERVICESTATE:-${NAGIOS_HOSTSTATE}}\",\"output\":\"${NAGIOS_SERVICEOUTPUT:-${NAGIOS_HOSTOUTPUT}}\",\"type\":\"${NAGIOS_NOTIFICATIONTYPE}\"}"
