# Gemini Skill - OpenClaw 集成版

通过 OpenClaw 的 Playwright MCP 技能与 Google Gemini 对话，支持**登录状态持久化**、长回复自动滚动、图片生成和完整内容提取。

## 📦 依赖

### 1. Playwright MCP（必须）

本 skill 依赖 [playwright-mcp](/skills/playwright-mcp) 技能。

**安装 Playwright MCP：**

```bash
# 1. 安装 mcporter
npm install -g mcporter

# 2. 启动 MCP 服务器（首次）
cd skills/playwright-mcp
./playwright.sh start

# 或指定端口
playwright-cli --browser chromium --port 3005 --user-data-dir ~/.config/gemini-browser-profile
```

### 2. 系统要求

- macOS + Chrome 浏览器
- Node.js + npm
- playwright-cli: `npm install -g playwright`

---

## 🚀 首次使用

```bash
cd skills/gemini

# 1. 启动专用浏览器（只需一次）
./gemini.sh start

# 2. 在浏览器中登录 Google 账户
#    登录后状态自动保存到 ~/.config/gemini-browser-profile/

# 3. 之后使用
./gemini.sh open        # 自动登录
./gemini.sh chat "hi"  # 开始对话
```

---

## 📖 使用方法

### 命令速查

| 命令 | 说明 |
|------|------|
| `./gemini.sh start` | 启动专用浏览器（首次） |
| `./gemini.sh open` | 打开 Gemini（自动登录） |
| `./gemini.sh chat "问题"` | 完整对话（自动滚动+提取） |
| `./gemini.sh image "提示词"` | 生成图片（需登录） |
| `./gemini.sh feishu` | 发送到飞书 |

### 详细用法

```bash
# 首次登录
./gemini.sh start  # 后台启动浏览器

# 日常使用
./gemini.sh open                    # 打开 Gemini
./gemini.sh chat "Sora 原理是什么？"  # 对话
./gemini.sh image "三文鱼"           # 生成图片
./gemini.sh feishu                  # 发送到飞书
```

---

## 🔧 OpenClaw 集成

### MCP 工具列表

通过 playwright-mcp 提供以下工具：

| 工具 | 说明 | 示例 |
|------|------|------|
| `browser_navigate` | 导航 | `url:"https://gemini.google.com"` |
| `browser_type` | 输入文本 | `text:"hi" ref:"e5"` |
| `browser_press_key` | 按键 | `key:"Enter"` |
| `browser_click` | 点击 | `ref:"e10"` |
| `browser_snapshot` | 页面快照 | 获取 DOM 结构 |
| `browser_take_screenshot` | 截图 | |
| `browser_wait_for` | 等待 | `timeout:5000` |

### 在 OpenClaw 中使用

```bash
# 进入 playwright-mcp 目录
cd skills/playwright-mcp

# 调用 MCP 工具
./playwright.sh playwright.browser_navigate url:"https://gemini.google.com"
./playwright.sh playwright.browser_type text:"你好 Gemini" ref:"e5"
./playwright.sh playwright.browser_press_key key:"Enter"
```

---

## 📁 文件结构

```
gemini-skill/
├── gemini.sh                      # 主脚本（11个命令）
├── SKILL.md                       # 本文档
├── start-gemini-browser.sh        # 启动脚本
└── README.md                      # 快速入门
```

---

## ⚠️ 注意事项

1. **首次使用**：必须 `./gemini.sh start` 并登录一次
2. **图片生成**：需要 Gemini Advanced 订阅
3. **分享链接**：有效期 7 天
4. **后台运行**：`./gemini.sh start &`
5. **停止服务器**：`Ctrl+C` 或 `./gemini.sh stop`

---

## 🔗 相关资源

- [Playwright MCP Skill](/skills/playwright-mcp)
- [OpenClaw 文档](https://docs.openclaw.ai)
- [GitHub 仓库](https://github.com/hungyinkam-lab/gemini-skill)
