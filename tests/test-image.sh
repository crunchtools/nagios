#!/bin/bash
# Test suite for quay.io/crunchtools/nagios
# Usage: ./test-image.sh --static <image>
#        ./test-image.sh --runtime <image>

set -uo pipefail

RUNTIME="${CONTAINER_RUNTIME:-docker}"
PASS=0
FAIL=0

check() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

run_in_image() {
    $RUNTIME run --rm --entrypoint /bin/sh "$IMAGE" -c "$*"
}

static_tests() {
    IMAGE="$1"
    echo "=== Static tests for $IMAGE ==="

    check "nagios package installed"            run_in_image "rpm -q nagios"
    check "nagios-plugins-http installed"        run_in_image "rpm -q nagios-plugins-http"
    check "nagios-plugins-tcp installed"         run_in_image "rpm -q nagios-plugins-tcp"
    check "nagios-plugins-load installed"        run_in_image "rpm -q nagios-plugins-load"
    check "nagios-plugins-disk installed"        run_in_image "rpm -q nagios-plugins-disk"
    check "nagios-plugins-nrpe installed"        run_in_image "rpm -q nagios-plugins-nrpe"
    check "curl installed"                       run_in_image "rpm -q curl"
    check "jq installed"                         run_in_image "rpm -q jq"
    check "notify_hermes.sh exists"              run_in_image "test -x /usr/local/bin/notify_hermes.sh"
    check "commands.cfg exists"                  run_in_image "test -f /etc/nagios/objects/commands.cfg"
    check "contacts.cfg exists"                  run_in_image "test -f /etc/nagios/objects/contacts.cfg"
    check "templates.cfg exists"                 run_in_image "test -f /etc/nagios/objects/templates.cfg"
    check "timeperiods.cfg exists"               run_in_image "test -f /etc/nagios/objects/timeperiods.cfg"
    check "nagios service enabled"               run_in_image "systemctl is-enabled nagios"
    check "httpd service enabled"                run_in_image "systemctl is-enabled httpd"
    check "nagios restart drop-in exists"        run_in_image "test -f /etc/systemd/system/nagios.service.d/restart.conf"
    check "entrypoint is /sbin/init" \
        $RUNTIME inspect "$IMAGE" --format '{{index .Config.Entrypoint 0}}' | grep -q /sbin/init
}

runtime_tests() {
    local image="$1"
    local container="nagios-test-$$"
    echo "=== Runtime tests for $image ==="

    trap "$RUNTIME rm -f $container >/dev/null 2>&1 || true" EXIT

    $RUNTIME run -d --name "$container" \
        --privileged --cgroupns=host \
        --tmpfs /tmp \
        -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
        "$image"

    echo "  Waiting for systemd..."
    for i in $(seq 1 30); do
        state=$($RUNTIME exec "$container" systemctl is-system-running 2>/dev/null || echo "starting")
        if [ "$state" = "running" ] || [ "$state" = "degraded" ]; then
            echo "  systemd reached: $state (${i}s)"
            break
        fi
        sleep 1
    done

    sleep 3

    check "nagios process running" \
        $RUNTIME exec "$container" pgrep -x nagios

    check "httpd process running" \
        $RUNTIME exec "$container" pgrep -x httpd

    check "nagios service active" \
        $RUNTIME exec "$container" systemctl is-active nagios

    check "httpd service active" \
        $RUNTIME exec "$container" systemctl is-active httpd

    check "port 80 listening" \
        $RUNTIME exec "$container" ss -tlnp '( sport = :80 )'

    check "nagios web UI responds" \
        $RUNTIME exec "$container" curl -s -o /dev/null -w '%{http_code}' http://localhost/nagios/ | grep -qE '200|401'

    if [ $FAIL -gt 0 ]; then
        echo "  --- DEBUG ---"
        $RUNTIME exec "$container" journalctl -u nagios --no-pager 2>&1 || true
    fi
}

case "${1:-}" in
    --static)  static_tests "${2:?image required}" ;;
    --runtime) runtime_tests "${2:?image required}" ;;
    *)
        static_tests "${2:?image required}"
        runtime_tests "$2"
        ;;
esac

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
