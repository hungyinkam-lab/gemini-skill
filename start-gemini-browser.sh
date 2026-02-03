#!/bin/bash
# 启动 Gemini 专用浏览器（带持久化登录状态）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GEMINI_USER_DATA_DIR="${HOME}/.config/gemini-browser-profile"
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PORT=3005

mkdir -p "$GEMINI_USER_DATA_DIR"

echo "========================================"
echo " Gemini 浏览器（带登录状态持久化）"
echo "========================================"
echo "用户数据目录: $GEMINI_USER_DATA_DIR"
echo "浏览器端口: $PORT"
echo ""
echo "首次启动后，请登录 Google 账户。"
echo "登录后，状态会被保存，下次启动自动登录。"
echo ""
echo "按 Ctrl+C 停止浏览器"
echo "========================================"

# 检查端口是否被占用
if lsof -i :$PORT &>/dev/null; then
    echo "端口 $PORT 已被占用，先停止现有进程..."
    pkill -f "playwright.*$PORT" 2>/dev/null
    sleep 2
fi

# 启动 Playwright MCP 服务器（带用户数据目录）
exec playwright-cli \
    --browser chromium \
    --port $PORT \
    --executable-path "$CHROME_PATH" \
    --user-data-dir "$GEMINI_USER_DATA_DIR"
