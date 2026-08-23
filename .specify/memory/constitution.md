# Nagios Container Constitution

> **Version:** 1.0.0
> **Ratified:** 2026-08-22
> **Status:** Active
> **Inherits:** [crunchtools/constitution](https://github.com/crunchtools/constitution) v1.x
> **Profile:** Container Image

## Image Purpose

Nagios Core monitoring for all crunchtools infrastructure on lotor. Replaces Zabbix (RT #1459). Dual notification: email via local Postfix relay + webhook via Trentina alert ingress to Hermes agent.

## Base Image

`quay.io/crunchtools/ubi10-httpd` — provides Apache httpd for the Nagios CGI web interface. No PHP or Perl needed (Nagios CGIs are compiled C).

## Packages (from EPEL 10)

- `nagios` — Nagios Core daemon
- `nagios-plugins-all` — full plugin set
- `nagios-plugins-nrpe` — NRPE client for host-level checks
- `nagios-plugins-by_ssh` — SSH-based remote checks
- `curl` — for Trentina webhook notifications
- `jq` — JSON processing in notification scripts

## Configuration

- Base configs (commands, contacts, templates, timeperiods) baked into image at `/etc/nagios/objects/`
- Runtime host/service configs mounted from host at `/etc/nagios/objects/custom/`
- Runtime configs tracked in `fatherlinux/lotor.dc3.crunchtools.com-srv` repo

## Notifications

Two contacts in every contact group:
1. **scott** — email via local Postfix relay (no credentials to expire)
2. **hermes** — webhook via Trentina coded URL to Hermes agent

## Testing

- Static: package installation, config file presence, systemd enablement
- Runtime: services start (nagios, httpd), web UI responds, port 80 listening
