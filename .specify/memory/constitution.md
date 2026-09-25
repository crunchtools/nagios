# Nagios Container Constitution

> **Version:** 1.0.1
> **Ratified:** 2026-08-22
> **Status:** Active
> **Inherits:** [crunchtools/constitution](https://github.com/crunchtools/constitution) v1.17.0
> **Profile:** Container Image

## License

AGPL-3.0-or-later.

## Versioning

Semantic Versioning 2.0.0. The image version tracks this repo's packaging and
configuration, not the upstream Nagios Core release — a rebuild that only picks
up a newer EPEL `nagios` RPM is a PATCH here.

## Registry

Published to `quay.io/crunchtools/nagios`.

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

## Containerfile Conventions

Single `Containerfile` at the repo root. Packages install with `dnf` from EPEL 10
in one layer, followed by `dnf clean all`. OCI `LABEL` metadata declares the
maintainer, description, source repo and license.

## Testing

`tests/test-image.sh` runs in CI on every push and pull request, against an image
built from the current tree, before anything is pushed to Quay.

- Build test: the image must build from the `Containerfile` with no cached layers
- Static: package installation, config file presence, systemd enablement
- Smoke test (runtime): services start (nagios, httpd), web UI responds, port 80
  listening

## Quality Gates

A push to `quay.io/crunchtools/nagios` happens only after the build, static and
smoke tests all pass. A failing test fails the workflow and blocks the push.
