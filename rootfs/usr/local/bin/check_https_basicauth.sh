#!/bin/bash
# HTTPS check with HTTP Basic Auth from a credentials file.
# Usage: check_https_basicauth.sh <hostname> <ip> <creds-file>
# The creds file contains a single line: user:password

HOST="$1"
IP="$2"
CREDS=$(cat "$3" 2>/dev/null)

if [ -z "$CREDS" ]; then
    echo "UNKNOWN - Cannot read credentials file $3"
    exit 3
fi

/usr/lib64/nagios/plugins/check_http -H "$HOST" -I "$IP" -p 443 --ssl --sni -a "$CREDS" -f follow -t 15
