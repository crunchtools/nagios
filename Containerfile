FROM quay.io/crunchtools/ubi10-httpd

# Register with RHSM using activation key (secrets mounted at build time, never in image layers)
RUN --mount=type=secret,id=activation_key \
    --mount=type=secret,id=org_id \
    if [ -f /run/secrets/activation_key ] && [ -f /run/secrets/org_id ]; then \
        subscription-manager register \
            --activationkey="$(cat /run/secrets/activation_key)" \
            --org="$(cat /run/secrets/org_id)"; \
    fi

# EPEL 10 for Nagios packages
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
    mailx \
    && dnf clean all

# Unregister from RHSM to avoid leaking entitlements
RUN subscription-manager unregister 2>/dev/null || true

# Structural setup — these rarely change
RUN chown -R root:nagios /etc/nagios/private && \
    mkdir -p /var/spool/nagios/checkresults /var/spool/nagios/cmd \
             /var/log/nagios/rw /var/log/nagios/spool \
             /etc/nagios/objects/custom /etc/nagios/auth && \
    chown -R nagios:nagios /var/spool/nagios /var/log/nagios && \
    chown root:nagios /etc/nagios/objects/custom && \
    echo "cfg_dir=/etc/nagios/objects/custom" >> /etc/nagios/nagios.cfg && \
    sed -i 's/nagiosadmin/admin/g' /etc/nagios/cgi.cfg && \
    chmod u+s /usr/lib64/nagios/plugins/check_ping && \
    usermod -aG nagios apache && \
    chmod 2770 /var/spool/nagios/cmd && \
    rm -f /etc/httpd/conf.d/welcome.conf

# Enable services
RUN systemctl enable nagios httpd

LABEL maintainer="fatherlinux <scott.mccarty@crunchtools.com>"
LABEL description="Nagios Core monitoring — all configs bind-mounted from host"
LABEL org.opencontainers.image.source=https://github.com/crunchtools/nagios
LABEL org.opencontainers.image.description="Nagios Core on UBI 10 — config, scripts, and credentials are bind-mounted at runtime"
LABEL org.opencontainers.image.licenses=AGPL-3.0-or-later

ENTRYPOINT ["/sbin/init"]
