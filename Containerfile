FROM quay.io/crunchtools/ubi10-httpd

# Register with RHSM using activation key (secrets mounted at build time, never in image layers)
RUN --mount=type=secret,id=activation_key \
    --mount=type=secret,id=org_id \
    if [ -f /run/secrets/activation_key ] && [ -f /run/secrets/org_id ]; then \
        subscription-manager register \
            --activationkey="$(cat /run/secrets/activation_key)" \
            --org="$(cat /run/secrets/org_id)"; \
    fi

# EPEL 10 for Nagios packages — install BEFORE rootfs overlay so RPM creates
# all default configs, dirs, and the nagios user. Our overlay then replaces
# only the files we customize (commands, contacts, templates, timeperiods).
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

# Overlay custom configs ON TOP of RPM defaults
COPY rootfs/ /

# Fix ownership: EPEL nagios RPM installs private/resource.cfg as root:root
# but nagios reads it as uid nagios. Also ensure runtime directories exist.
RUN chown -R root:nagios /etc/nagios/private && \
    mkdir -p /var/spool/nagios/checkresults /var/spool/nagios/cmd \
             /var/log/nagios/rw /var/log/nagios/spool && \
    chown -R nagios:nagios /var/spool/nagios /var/log/nagios

# Wire custom config directory and set CGI auth user
RUN mkdir -p /etc/nagios/objects/custom && \
    chown root:nagios /etc/nagios/objects/custom && \
    echo "cfg_dir=/etc/nagios/objects/custom" >> /etc/nagios/nagios.cfg && \
    sed -i 's/nagiosadmin/admin/g' /etc/nagios/cgi.cfg

# Remove welcome page, serve Nagios web UI
RUN rm -f /etc/httpd/conf.d/welcome.conf

# Make notification scripts executable
RUN chmod +x /usr/local/bin/notify_hermes.sh

# Install mailx for email notifications via Postfix relay
RUN dnf install -y mailx && dnf clean all

# Enable services
RUN systemctl enable nagios httpd

LABEL maintainer="fatherlinux <scott.mccarty@crunchtools.com>"
LABEL description="Nagios Core monitoring with Hermes agent notification"
LABEL org.opencontainers.image.source=https://github.com/crunchtools/nagios
LABEL org.opencontainers.image.description="Nagios Core on UBI 10 with dual notification: email via Postfix + webhook via Trentina/Hermes"
LABEL org.opencontainers.image.licenses=AGPL-3.0-or-later

ENTRYPOINT ["/sbin/init"]
