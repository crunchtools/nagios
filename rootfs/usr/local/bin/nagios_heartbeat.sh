#!/bin/bash
# Dead-man's switch: sends a heartbeat email every 6 hours through the same
# Postfix relay that Nagios uses for notifications. If Scott stops receiving
# these, the email delivery path is broken.

RECIPIENT="scott.mccarty@gmail.com"
MYHOST="${HOSTNAME:-nagios}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M %Z')

/usr/bin/printf "%b" \
  "Nagios heartbeat from ${MYHOST} at ${TIMESTAMP}.\n\n" \
  "This confirms the email notification path is working.\n" \
  "If you stop receiving these every 6 hours, investigate immediately.\n" \
  | /usr/bin/mail -S mta=smtp://10.88.0.1:25 -S from=nagios@crunchtools.com \
    -s "[NAGIOS HEARTBEAT] ${MYHOST} - ${TIMESTAMP}" "${RECIPIENT}"
