#!/bin/bash
# Gemini 工具箱 - 包含登录状态持久化功能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 配置
GEMINI_USER_DATA_DIR="${HOME}/.config/gemini-browser-profile"
GEMINI_MCP_PORT=3005
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

mkdir -p "$GEMINI_USER_DATA_DIR"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查 MCP 服务器状态
check_mcp() {
    if ! lsof -i :$GEMINI_MCP_PORT &>/dev/null; then
        return 1
    fi
    return 0
}

# 启动 MCP 服务器
start_mcp() {
    if check_mcp; then
        log_info "MCP 服务器已运行（端口 $GEMINI_MCP_PORT）"
        return 0
    fi
    
    log_info "启动 Playwright MCP 服务器..."
    log_info "用户数据目录: $GEMINI_USER_DATA_DIR"
    
    # 后台启动
    playwright-cli \
        --browser chromium \
        --port $GEMINI_MCP_PORT \
        --executable-path "$CHROME_PATH" \
        --user-data-dir "$GEMINI_USER_DATA_DIR" \
        > /tmp/gemini-mcp.log 2>&1 &
    
    local pid=$!
    sleep 3
    
    if check_mcp; then
        log_info "MCP 服务器已启动（PID: $pid）"
        echo "$pid" > /tmp/gemini-mcp.pid
    else
        log_error "MCP 服务器启动失败"
        cat /tmp/gemini-mcp.log
        return 1
    fi
}

# 停止 MCP 服务器
stop_mcp() {
    if [ -f /tmp/gemini-mcp.pid ]; then
        local pid=$(cat /tmp/gemini-mcp.pid)
        log_info "停止 MCP 服务器（PID: $pid）..."
        kill $pid 2>/dev/null
        rm /tmp/gemini-mcp.pid
    fi
}

# 调用 MCP 工具
mcp_call() {
    local tool="$1"
    shift
    mcporter call --server playwright --tool "$tool" "$@" 2>/dev/null || \
    (cd "$SCRIPT_DIR/../playwright-mcp" && ./playwright.sh "$tool" "$@")
}

# 打开 Gemini
cmd_open() {
    start_mcp
    log_info "打开 Gemini..."
    mcp_call playwright.browser_navigate url:"https://gemini.google.com"
}

# 截图
cmd_screenshot() {
    start_mcp
    log_info "截图..."
    mcp_call playwright.browser_take_screenshot
}

# 获取页面快照
cmd_snapshot() {
    start_mcp
    log_info "获取页面快照..."
    mcp_call playwright.browser_snapshot
}

# 提取 Gemini 回复的完整文本
cmd_extract() {
    start_mcp
    log_info "提取 Gemini 回复内容..."
    
    mcp_call playwright.browser_snapshot > /tmp/gemini_snapshot.txt 2>&1
    
    python3 << 'PYEOF'
import re
import sys

try:
    with open('/tmp/gemini_snapshot.txt', 'r') as f:
        content = f.read()
    
    texts = []
    seen = set()
    
    para_pattern = r'- paragraph \[.*?\]:\s*([^\n]+)'
    matches = re.findall(para_pattern, content)
    
    for match in matches:
        text = match.strip()
        if (len(text) >= 10 and 
            not text.startswith('/url:') and 
            not text.startswith('http') and
            'paragraph' not in text and
            'text:' not in text and
            'ref=' not in text and
            'img' not in text and
            'cursor=' not in text and
            'Gemini 的回答' not in text and
            'Ask Gemini' not in text and
            'Google' not in text and
            '问我' not in text and
            '在此处输入' not in text and
            'OpenClaw 有哪些玩法和功能' not in text):
            
            text = re.sub(r'\s+', ' ', text).strip()
            text_hash = text[:50]
            if text_hash not in seen:
                seen.add(text_hash)
                texts.append(text)
    
    heading_pattern = r'- heading .*? \[.*?\]:\s*([^\n]+)'
    matches = re.findall(heading_pattern, content)
    for match in matches:
        text = match.strip()
        text = re.sub(r'\s+', ' ', text).strip()
        if len(text) >= 5 and 'OpenClaw 有哪些玩法和功能' not in text:
            text_hash = text[:50]
            if text_hash not in seen:
                seen.add(text_hash)
                texts.append(text)
    
    for text in texts:
        print(text)
        print()
        
except Exception as e:
    print(f"解析错误: {e}", file=sys.stderr)
PYEOF
}

# 等待回复并下滑
cmd_wait_and_scroll() {
    start_mcp
    log_info "等待 10 秒..."
    sleep 10
    
    log_info "下滑加载更多..."
    mcp_call playwright.browser_press_key key:"PageDown"
    sleep 3
    mcp_call playwright.browser_press_key key:"PageDown"
    sleep 2
    
    log_info "滚动到顶部..."
    mcp_call playwright.browser_press_key key:"Home"
}

# 完整提问流程
cmd_chat() {
    local question="${1:-OpenClaw 有哪些玩法和功能？请详细介绍}"
    
    start_mcp
    log_info "开始提问: $question"
    
    mcp_call playwright.browser_snapshot > /tmp/gemini_snapshot.txt 2>&1
    
    local input_ref=$(grep 'textbox' /tmp/gemini_snapshot.txt | grep -o 'ref=[^]]*' | head -1 | sed 's/ref=//')
    
    if [ -z "$input_ref" ]; then
        log_error "未找到输入框"
        return 1
    fi
    
    log_info "找到输入框 ref: $input_ref"
    
    mcp_call "playwright.browser_type(ref: \"$input_ref\", text: \"$question\")"
    mcp_call playwright.browser_press_key key:"Enter"
    
    cmd_wait_and_scroll
    cmd_extract
}

# 打开工具菜单
cmd_tools() {
    start_mcp
    log_info "打开工具菜单..."
    
    mcp_call playwright.browser_snapshot > /tmp/gemini_tools.txt 2>&1
    local tool_ref=$(grep 'button "工具"' /tmp/gemini_tools.txt | grep -o 'ref=[^]]*' | sed 's/ref=//' | tr -d '[]')
    
    if [ -z "$tool_ref" ]; then
        log_error "未找到工具按钮"
        return 1
    fi
    
    mcp_call "playwright.browser_click(ref: \"$tool_ref\")"
}

# 生成图片（自动获取分享链接并发送到飞书）
cmd_image() {
    local target="${2:-ou_d9e959b492ce5f83caa3ff8b867bd1d4}"
    local prompt="${1:-一只可爱的三文鱼}"
    
    start_mcp
    log_info "生成图片: $prompt"
    
    cmd_tools
    sleep 2
    
    mcp_call playwright.browser_snapshot > /tmp/gemini_image.txt 2>&1
    local img_btn=$(grep 'button "生成图片"\|button "🍌 Create image"' /tmp/gemini_image.txt | grep -o 'ref=[^]]*' | sed 's/ref=//' | tr -d '[]' | head -1)
    
    if [ -z "$img_btn" ]; then
        log_error "未找到生成图片按钮，可能需要先登录"
        return 1
    fi
    
    log_info "点击生成图片按钮"
    mcp_call "playwright.browser_click(ref: \"$img_btn\")"
    sleep 2
    
    mcp_call playwright.browser_snapshot > /tmp/gemini_image_input.txt 2>&1
    local new_input=$(grep 'textbox' /tmp/gemini_image_input.txt | grep -v "Ask Gemini\|Describe" | grep -o 'ref=[^]]*' | head -1 | sed 's/ref=//')
    
    if [ -z "$new_input" ]; then
        log_error "未找到图片生成输入框"
        return 1
    fi
    
    log_info "输入提示词..."
    mcp_call "playwright.browser_type(ref: \"$new_input\", text: \"$prompt\")"
    mcp_call playwright.browser_press_key key:"Enter"
    
    log_info "等待图片生成（15-30秒）..."
    sleep 25
    
    log_info "点击 Share image 按钮..."
    mcp_call playwright.browser_snapshot > /tmp/gemini_share.txt 2>&1
    
    # 查找 Share image 按钮
    local share_btn=$(grep 'button "Share image"' /tmp/gemini_share.txt | grep -o 'ref=[^]]*' | sed 's/ref=//' | tr -d '[]' | head -1)
    
    if [ -z "$share_btn" ]; then
        log_error "未找到 Share image 按钮"
        return 1
    fi
    
    mcp_call "playwright.browser_click(ref: \"$share_btn\")"
    sleep 3
    
    log_info "获取分享链接..."
    mcp_call playwright.browser_snapshot > /tmp/gemini_link.txt 2>&1
    
    # 提取分享链接
    local share_link=$(grep 'link "gemini.google.com/share' /tmp/gemini_link.txt | grep -o 'https://[^"]*' | head -1)
    
    if [ -z "$share_link" ]; then
        log_error "未找到分享链接"
        return 1
    fi
    
    log_info "找到分享链接: $share_link"
    
    # 发送到飞书
    log_info "发送到飞书..."
    message action=send to="$target" message="Gemini 生成的图片（7天有效）:\n$share_link\n\n提示词: $prompt"
    
    log_info "完成！分享链接已发送到飞书"
}

# 发送到飞书
cmd_feishu() {
    local target="${1:-ou_d9e959b492ce5f83caa3ff8b867bd1d4}"
    
    local image_path=$(cat /tmp/gemini_last_image.txt 2>/dev/null)
    if [ -z "$image_path" ] || [ ! -f "$image_path" ]; then
        image_path=$(ls -t /tmp/playwright-mcp-output/*/page*.png 2>/dev/null | head -1)
    fi
    
    if [ -z "$image_path" ] || [ ! -f "$image_path" ]; then
        log_error "未找到截图文件，请先生成图片"
        return 1
    fi
    
    log_info "发送图片到飞书..."
    message action=send to="$target" message="这是 Gemini 生成的图片" filePath="$image_path"
    log_info "已发送"
}

# 显示帮助
cmd_help() {
    echo "Gemini 工具箱 - 支持登录状态持久化"
    echo ""
    echo "使用方法: ./gemini.sh <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  start           启动专用浏览器（首次登录用）"
    echo "  open            打开 Gemini（自动启动 MCP）"
    echo "  chat [问题]     完整对话流程"
    echo "  image [提示词]  生成图片并发送到飞书（需登录）"
    echo "  feishu          发送最新图片到飞书"
    echo "  extract         提取回复文本"
    echo "  screenshot      截图"
    echo "  stop            停止 MCP 服务器"
    echo "  status          检查 MCP 状态"
    echo "  help            显示帮助"
    echo ""
    echo "示例:"
    echo "  ./gemini.sh start                    # 首次登录"
    echo "  ./gemini.sh open                     # 打开 Gemini"
    echo "  ./gemini.sh image 一只三文鱼          # 生成图片并发送"
    echo "  ./gemini.sh feishu                   # 发送图片到飞书"
}

# 主入口
main() {
    local cmd="${1:-help}"
    shift || true
    
    case "$cmd" in
        start)
            start_mcp
            echo ""
            echo "按 Ctrl+C 停止服务器"
            echo "登录后状态会自动保存"
            wait
            ;;
        open)
            cmd_open
            ;;
        chat)
            cmd_chat "$@"
            ;;
        image)
            cmd_image "$@"
            ;;
        feishu)
            cmd_feishu "$@"
            ;;
        extract)
            cmd_extract
            ;;
        screenshot)
            cmd_screenshot
            ;;
        snapshot)
            cmd_snapshot
            ;;
        scroll)
            cmd_wait_and_scroll
            ;;
        tools)
            cmd_tools
            ;;
        stop)
            stop_mcp
            ;;
        status)
            if check_mcp; then
                log_info "MCP 服务器运行中（端口 $GEMINI_MCP_PORT）"
                log_info "用户数据目录: $GEMINI_USER_DATA_DIR"
            else
                log_warn "MCP 服务器未运行"
                log_info "运行 ./gemini.sh start 启动"
            fi
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "未知命令: $cmd"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
