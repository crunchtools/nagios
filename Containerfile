FROM quay.io/crunchtools/ubi10-httpd

# Register with RHSM using activation key (secrets mounted at build time, never in image layers)
RUN --mount=type=secret,id=activation_key \
    --mount=type=secret,id=org_id \
    if [ -f /run/secrets/activation_key ] && [ -f /run/secrets/org_id ]; then \
        subscription-manager register \
            --activationkey="$(cat /run/secrets/activation_key)" \
            --org="$(cat /run/secrets/org_id)"; \
    fi

COPY rootfs/ /

# EPEL 10 for Nagios packages
# nagios-plugins-all drags in disk_smb which needs perl(utf8::all) — missing in UBI 10.
# Install the plugins we actually use instead.
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm && \
    dnf install -y \
    nagios \
    nagios-plugins-ping \
    nagios-plugins-http \
    nagios-plugins-tcp \
    nagios-plugins-load \
    nagios-plugins-disk \
    nagios-plugins-procs \
    nagios-plugins-swap \
    nagios-plugins-users \
    nagios-plugins-ssh \
    nagios-plugins-nrpe \
    nagios-plugins-by_ssh \
    nagios-plugins-ntp \
    nagios-plugins-dns \
    curl \
    jq \
    && dnf clean all

# Unregister from RHSM to avoid leaking entitlements
RUN subscription-manager unregister 2>/dev/null || true

# Serve Nagios at /nagios (default), remove welcome page
RUN rm -f /etc/httpd/conf.d/welcome.conf

# Ensure Nagios runtime directories exist and resource.cfg is readable.
# The EPEL package sometimes skips these in a container context.
RUN mkdir -p /var/spool/nagios/checkresults /var/log/nagios/rw /var/log/nagios/spool /var/spool/nagios/cmd && \
    chown -R nagios:nagios /var/spool/nagios /var/log/nagios && \
    mkdir -p /etc/nagios/private && \
    cp -n /etc/nagios/private/resource.cfg.rpmnew /etc/nagios/private/resource.cfg 2>/dev/null; \
    test -f /etc/nagios/private/resource.cfg || echo '$USER1$=/usr/lib64/nagios/plugins' > /etc/nagios/private/resource.cfg && \
    chown root:nagios /etc/nagios/private/resource.cfg && \
    chmod 640 /etc/nagios/private/resource.cfg && \
    ls -la /etc/nagios/private/ && cat /etc/nagios/private/resource.cfg

# Make notification scripts executable
RUN chmod +x /usr/local/bin/notify_hermes.sh

# Enable services
RUN systemctl enable nagios httpd

LABEL maintainer="fatherlinux <scott.mccarty@crunchtools.com>"
LABEL description="Nagios Core monitoring with Hermes agent notification"
LABEL org.opencontainers.image.source=https://github.com/crunchtools/nagios
LABEL org.opencontainers.image.description="Nagios Core on UBI 10 with dual notification: email via Postfix + webhook via Trentina/Hermes"
LABEL org.opencontainers.image.licenses=AGPL-3.0-or-later

ENTRYPOINT ["/sbin/init"]
