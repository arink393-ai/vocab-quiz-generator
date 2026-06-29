#!/usr/bin/env bash
# 一鍵更新腳本：把新的 HTML 推上 GitHub Pages
#
# 用法：
#   ./update.sh                         # 直接用目前資料夾的 index.html
#   ./update.sh ~/Downloads/某檔.html    # 先用指定 HTML 覆蓋 index.html，再上線
#
set -euo pipefail

# --- 設定 ---
export PATH="$HOME/.local/bin:$PATH"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
OWNER="arink393-ai"
REPO="vocab-quiz-generator"
URL="https://${OWNER}.github.io/${REPO}/"
GIT_NAME="arink393-ai"
GIT_EMAIL="arink393@gmail.com"

cd "$REPO_DIR"

# --- 1. 若有指定來源檔，覆蓋 index.html ---
if [ "${1:-}" != "" ]; then
  SRC="$1"
  if [ ! -f "$SRC" ]; then
    echo "❌ 找不到檔案：$SRC"; exit 1
  fi
  cp "$SRC" index.html
  echo "📄 已用 $SRC 覆蓋 index.html"
fi

# --- 2. 有沒有變更？（含未追蹤的新檔案）---
if [ -z "$(git status --porcelain)" ]; then
  echo "✅ 沒有任何變更，不需要更新。"; exit 0
fi

# --- 3. commit + push ---
MSG="${2:-Update site $(date '+%Y-%m-%d %H:%M')}"
git add -A
git -c user.name="$GIT_NAME" -c user.email="$GIT_EMAIL" commit -q -m "$MSG"
echo "📝 已 commit：$MSG"
git push -q origin main
echo "🚀 已推送到 GitHub"

# --- 4. 等 Pages 重建並確認上線 ---
echo "⏳ 等待 GitHub Pages 重建…"
for i in $(seq 1 25); do
  STATUS=$(gh api "repos/${OWNER}/${REPO}/pages" --jq .status 2>/dev/null || echo "?")
  if [ "$STATUS" = "built" ]; then
    echo "✅ 已上線！網址：$URL"
    exit 0
  fi
  printf "  第 %d 次：build=%s\n" "$i" "$STATUS"
  sleep 12
done

echo "⚠️ 等待逾時，但已推送成功。請稍後再開：$URL"
