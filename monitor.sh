#!/bin/bash
set -e

CONFIG_FILE="config.json"
STATUS_FILE="status.json"
TMP_FILE="status_tmp.json"
LOG_DIR="logs"
TIMEOUT=20
NOW=$(date '+%Y-%m-%d %H:%M:%S')
YEAR=$(date +%G)
WEEK=$(date +%V)
LOG_FILE="${LOG_DIR}/monitor-${YEAR}-W${WEEK}.json"

mkdir -p "$LOG_DIR"
[ ! -f "$STATUS_FILE" ] && echo "{}" > "$STATUS_FILE"
[ ! -f "$LOG_FILE" ] && echo "[]" > "$LOG_FILE"

jq -c '.[]' "$CONFIG_FILE" | while read -r site; do
  NAME=$(echo "$site" | jq -r '.name')
  URL=$(echo "$site" | jq -r '.url')
  IP=$(echo "$site" | jq -r '.ip // empty')

  echo "⏳ Testing $URL ..."

  CURL_CMD=(curl -v -L -s -k -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT")
  CURL_CMD+=(-A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36")

  if [ -n "$IP" ]; then
    HOST=$(echo "$URL" | sed -E 's#https?://([^/:]+).*#\1#')
    CURL_CMD+=(--resolve "$HOST:443:$IP")
  fi

  # 用 timeout 防止卡死
  HTTP_CODE=""
  EXIT_CODE=0
  CURL_OUTPUT=""

  if command -v timeout >/dev/null 2>&1; then
    CURL_OUTPUT=$(timeout ${TIMEOUT}s "${CURL_CMD[@]}" "$URL" 2>&1) || EXIT_CODE=$?
  else
    CURL_OUTPUT=$("${CURL_CMD[@]}" "$URL" 2>&1) || EXIT_CODE=$?
  fi

  # 提取最后3位数字作为 HTTP_CODE
  HTTP_CODE=$(echo "$CURL_OUTPUT" | tail -n1 | grep -oE '[0-9]{3}$' || echo "")

  echo "👉 $NAME: HTTP_CODE=$HTTP_CODE, EXIT_CODE=$EXIT_CODE"
  echo "----- curl verbose output for $NAME -----"
  echo "$CURL_OUTPUT"
  echo "-----------------------------------------"

  # 判定状态
  if [ "$EXIT_CODE" -ne 0 ]; then
    STATUS="offline"
  elif [ "$HTTP_CODE" == "200" ]; then
    STATUS="online"
  else
    STATUS="offline"
  fi

  LAST_STATUS=$(jq -r --arg name "$NAME" '.[$name] // "unknown"' "$STATUS_FILE")

  if [ "$STATUS" != "$LAST_STATUS" ]; then
    if [ "$STATUS" == "online" ]; then
      TEXT="✅ ${NAME} 网站状态变成『在线』"
    else
      TEXT="❌ ${NAME} 网站状态变成『不在线』"
    fi

    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d chat_id="${TELEGRAM_CHAT_ID}" \
      -d text="$TEXT"
  fi

  jq --arg name "$NAME" --arg status "$STATUS" '.[$name]=$status' "$STATUS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$STATUS_FILE"

  jq --arg time "$NOW" --arg name "$NAME" --arg status "$STATUS" \
    '. += [{"time": $time, "name": $name, "status": $status}]' "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
done

# 删除5周之前的日志文件
cd "$LOG_DIR"
ls -1tr monitor-*.json | head -n -5 | xargs -r rm
cd ..
