#!/bin/bash
# Dead-man's switch: sends a heartbeat email every 6 hours through the same
# Postfix relay that Nagios uses for notifications. If Scott stops receiving
# these, the email delivery path is broken.

RECIPIENT="scott.mccarty@gmail.com"
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M %Z')

/usr/bin/printf "%b" \
  "Nagios heartbeat from ${HOSTNAME} at ${TIMESTAMP}.\n\n" \
  "This confirms the email notification path is working.\n" \
  "If you stop receiving these every 6 hours, investigate immediately.\n" \
  | /usr/bin/mail -s "[NAGIOS HEARTBEAT] ${HOSTNAME} - ${TIMESTAMP}" "${RECIPIENT}"
