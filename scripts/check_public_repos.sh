#!/bin/bash
set -euo pipefail

# 必須環境変数のチェック
if [[ -z "${ORG_NAME:-}" ]]; then
  echo "Error: ORG_NAME is not set"
  exit 1
fi

if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
  echo "Error: SLACK_WEBHOOK_URL is not set"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALLOWLIST_FILE="${SCRIPT_DIR}/../allowed_public_repos.txt"

# GitHub APIでパブリックリポジトリ一覧を取得（認証不要）
echo "Fetching public repositories for organization: ${ORG_NAME}"

PUBLIC_REPOS=""
PAGE=1
PER_PAGE=100

while true; do
  RESPONSE=$(curl -s "https://api.github.com/orgs/${ORG_NAME}/repos?type=public&per_page=${PER_PAGE}&page=${PAGE}")

  # エラーチェック
  if echo "${RESPONSE}" | grep -q '"message"'; then
    echo "Error from GitHub API:"
    echo "${RESPONSE}"
    exit 1
  fi

  # リポジトリ名を抽出
  REPOS=$(echo "${RESPONSE}" | jq -r '.[].name' 2>/dev/null || echo "")

  if [[ -z "${REPOS}" ]]; then
    break
  fi

  PUBLIC_REPOS="${PUBLIC_REPOS}${REPOS}"$'\n'

  # 次のページがあるかチェック
  REPO_COUNT=$(echo "${RESPONSE}" | jq 'length')
  if [[ "${REPO_COUNT}" -lt "${PER_PAGE}" ]]; then
    break
  fi

  PAGE=$((PAGE + 1))
done

# 末尾の空行を削除
PUBLIC_REPOS=$(echo -n "${PUBLIC_REPOS}" | sed '/^$/d')

if [[ -z "${PUBLIC_REPOS}" ]]; then
  echo "No public repositories found."
  exit 0
fi

echo "Found public repositories:"
echo "${PUBLIC_REPOS}"

# 許可リストを読み込み（コメント行と空行を除外）
ALLOWED_REPOS=""
if [[ -f "${ALLOWLIST_FILE}" ]]; then
  ALLOWED_REPOS=$(grep -v '^#' "${ALLOWLIST_FILE}" | grep -v '^$' | tr -d '\r' || echo "")
fi

# 許可されていないパブリックリポジトリを検出
UNAUTHORIZED_REPOS=""
while IFS= read -r repo; do
  if [[ -z "${repo}" ]]; then
    continue
  fi

  if ! echo "${ALLOWED_REPOS}" | grep -qx "${repo}"; then
    UNAUTHORIZED_REPOS="${UNAUTHORIZED_REPOS}${repo}"$'\n'
  fi
done <<< "${PUBLIC_REPOS}"

# 末尾の改行を削除
UNAUTHORIZED_REPOS=$(echo -n "${UNAUTHORIZED_REPOS}" | sed '/^$/d')

if [[ -z "${UNAUTHORIZED_REPOS}" ]]; then
  echo "All public repositories are in the allowlist. No action needed."
  exit 0
fi

echo ""
echo "Unauthorized public repositories detected:"
echo "${UNAUTHORIZED_REPOS}"

# Slack通知用のリストを作成
REPO_LIST=""
while IFS= read -r repo; do
  if [[ -n "${repo}" ]]; then
    REPO_LIST="${REPO_LIST}• <https://github.com/${ORG_NAME}/${repo}|${repo}>\n"
  fi
done <<< "${UNAUTHORIZED_REPOS}"

# Slack通知を送信
PAYLOAD=$(cat <<EOF
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": ":warning: 未許可のパブリックリポジトリを検出",
        "emoji": true
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "以下のリポジトリが許可リストに含まれていません:\n\n${REPO_LIST}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "<https://github.com/orgs/${ORG_NAME}/repositories?type=public|Organization のリポジトリ一覧を確認>"
      }
    },
    {
      "type": "context",
      "elements": [
        {
          "type": "mrkdwn",
          "text": "意図的な公開であれば \`allowed_public_repos.txt\` にリポジトリ名を追加してください"
        }
      ]
    }
  ]
}
EOF
)

echo ""
echo "Sending Slack notification..."

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}" \
  "${SLACK_WEBHOOK_URL}")

if [[ "${HTTP_STATUS}" == "200" ]]; then
  echo "Slack notification sent successfully."
else
  echo "Failed to send Slack notification. HTTP status: ${HTTP_STATUS}"
  exit 1
fi
