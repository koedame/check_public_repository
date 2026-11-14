# check_public_repository

組織の公開リポジトリを定期的に取得し、`allowed_public_repos.txt` に載っていないものがあれば Slack に通知するスクリプトです。現在はアーカイブされています。

## 使い方

`scripts/check_public_repos.sh` を、環境変数 `ORG_NAME`、`SLACK_WEBHOOK_URL`、`CONFIG_REPO_URL` を設定して実行します。公開してよいリポジトリ名は `allowed_public_repos.txt` に 1 行 1 件で書きます。

## ライセンス

MIT License です。詳しくは [LICENSE](./LICENSE) を参照してください。
