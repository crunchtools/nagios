# Nagios Container Constitution

> **Version:** 1.1.0
> **Ratified:** 2026-08-22
> **Amended:** 2026-10-02
> **Status:** Active
> **Inherits:** [crunchtools/constitution](https://github.com/crunchtools/constitution) v1.18.0
> **Profile:** Container Image

This file holds what is specific to nagios. The fleet rules and the Container
Image profile (license, versioning, LABELs, the RHSM secret-mount pattern,
systemd conventions, registry, testing and quality gates) apply at the
inherited version and are checked against this repo's files by
`constitution.yml`. They are not restated here.

## Purpose

Nagios Core monitoring for all crunchtools infrastructure, replacing Zabbix
(RT #1459). Published as `quay.io/crunchtools/nagios`.

## Parent Image

`quay.io/crunchtools/ubi10-httpd`, for Apache serving the Nagios CGI web
interface. No PHP or Perl layer is needed: the Nagios CGIs are compiled C.

## Package Sources

Nagios is not in UBI or RHEL, so the image installs `epel-release` and takes
its packages from **EPEL 10**. It registers with RHSM at build time (secrets
`activation_key` and `org_id`, registration skipped when they are absent) so
EPEL dependencies resolve, and unregisters afterwards.

The image version tracks this repo's packaging and configuration, not the
upstream Nagios Core release: a rebuild that only picks up a newer EPEL
`nagios` RPM is a PATCH.

## Packages and Services

- **Packages:** nagios; nagios-plugins-ping, -http, -tcp, -load, -disk,
  -procs, -swap, -users, -ssh, -nrpe, -by_ssh, -ntp, -dns; curl, jq, mailx.
- **Enabled:** nagios, httpd, `nagios-fix-perms`.
- **nagios-fix-perms.service:** a oneshot ordered before nagios and httpd
  that re-adds `apache` to the `nagios` group and resets the command pipe
  directory to 2770 on every boot, because the container runs with
  `--tmpfs /etc`, which wipes `/etc/group` from the image layer.
- `check_ping` is setuid; the CGI admin user is renamed from `nagiosadmin`
  to `admin`; Apache's `welcome.conf` is removed.

## Runtime Configuration

The stock object configs (commands, contacts, templates, timeperiods) stay
in `/etc/nagios/objects/`. Host and service definitions, notification scripts
and credentials are bind-mounted at runtime: `nagios.cfg` gains
`cfg_dir=/etc/nagios/objects/custom`, and `/etc/nagios/auth` is created as a
mount point.

## Notifications

Every contact group carries two contacts: email to the maintainer through the
local Postfix relay (`mailx`, no credentials to expire), and a webhook through
Trentina's alert ingress to the Hermes agent (`curl`, `jq`).

## Image Tests

`tests/test-image.sh` runs in CI on every push and pull request, before
anything is pushed. `--static` checks packages, config file presence,
enabled services and the `/sbin/init` entrypoint; `--runtime` starts the
container and checks nagios and httpd are active, port 80 is listening and
the web UI responds.

## History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-08-22 | Initial Nagios Core container image |
| 1.0.1 | 2026-09-25 | Gatehouse review, triage and pre-commit gates |
| 1.1.0 | 2026-10-02 | Manifest under constitution v1.18.0: profile restatement removed, image specifics kept |
