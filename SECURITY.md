# Security Policy

## Reporting a vulnerability

Please report security problems privately through
[GitHub's private vulnerability reporting](https://github.com/koedame/check_public_repository/security/advisories/new).
Do not open a public issue for them.

We will reply within 7 days to confirm that we received your report, and keep you updated until it is fixed.

## Supported versions

This repository has no releases. Only the latest commit on the `main` branch gets security fixes.

## What counts as a vulnerability

- Problems in `scripts/check_public_repos.sh` or `.github/workflows/check-public-repos.yml`
  that could leak the workflow's secrets (such as the Slack webhook URL) or let someone run code in the workflow
- Ways to make the check miss a public repository that is not on the allowlist, or send misleading notifications
