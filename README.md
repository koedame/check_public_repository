# check_public_repository

**A scheduled GitHub Actions check that reports public repositories of an organization that are not on an allowlist, with a Slack notification.**

[![CodeQL](https://github.com/koedame/check_public_repository/actions/workflows/codeql.yml/badge.svg)](https://github.com/koedame/check_public_repository/actions/workflows/codeql.yml)
![License: MIT](https://img.shields.io/badge/license-MIT-0f7b6c)
![Status: retired](https://img.shields.io/badge/status-retired-lightgrey)

[Status](#status) · [Quick start](#quick-start) · [How it works](#how-it-works) · [License](#license)

It catches a repository that was made public by mistake: every public repository of the organization has to be listed in `allowed_public_repos.txt`, and anything else is posted to Slack. Once a day it also posts an "all clear" message, so you can tell that the check is still running.

## Status

This check is retired. The workflow is disabled and no longer runs, and the repository is not maintained. The allowlist is kept in sync with the organization's public repositories, but nothing reads it unless you enable the workflow again.

## Quick start

1. Fork or copy this repository into your organization.
2. In **Settings → Secrets and variables → Actions**, add the secret `SLACK_WEBHOOK_URL` (a Slack incoming webhook) and the variable `ORG_NAME` (the organization to watch).
3. Edit `allowed_public_repos.txt`: one repository name per line, without the organization name. Lines starting with `#` are comments.

   ```text
   # public on purpose
   my-oss-library
   public-docs
   ```

4. Open the **Actions** tab, enable the workflow **Check Public Repositories**, and press **Run workflow** once. It should finish without posting a warning.

## How it works

<details>
<summary>Schedule, API access and permissions</summary>

- The workflow runs every 5 minutes and once a day at 09:00 UTC (the daily run posts the "all clear" message).
- `scripts/check_public_repos.sh` reads `https://api.github.com/orgs/<ORG_NAME>/repos?type=public` without authentication, so it only sees repositories that are public.
- Repositories that are not in the allowlist are sent to the Slack webhook as one message.
- The workflow token is read-only (`contents: read`), and `actions/checkout` is pinned to a commit.
- Security reports: see [SECURITY.md](SECURITY.md).

</details>

## License

[MIT](LICENSE)
