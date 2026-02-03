---
name: gemini
description: 使用 Playwright MCP 与 Google Gemini 对话
---

# Gemini 工具箱

通过 Playwright MCP 浏览器自动化与 Google Gemini 进行对话，支持**登录状态持久化**、长回复自动滚动、图片生成和完整内容提取。

## 依赖

- [Playwright MCP](/skills/playwright-mcp) skill（需先安装配置）
- `playwright-cli` 命令（`npm install -g playwright`）
- 系统 Chrome 浏览器

## 首次使用（重要）

```bash
cd skills/gemini

# 1. 启动专用浏览器（这一步只需要做一次）
./gemini.sh start

# 2. 在打开的浏览器中登录 Google 账户
#    登录后，状态会自动保存到 ~/.config/gemini-browser-profile/

# 3. 之后每次使用只需要：
./gemini.sh open        # 自动登录
./gemini.sh chat "你的问题"
./gemini.sh image "生成图片"
```

## 使用方法

### 快速开始

```bash
cd skills/gemini

# 打开 Gemini（自动登录）
./gemini.sh open

# 完整对话流程（自动滚动+提取）
./gemini.sh chat "OpenClaw 有哪些功能？"

# 生成图片（需登录）
./gemini.sh image "一只三文鱼"

# 发送截图到飞书
./gemini.sh feishu
```

### 脚本参数

| 脚本 | 说明 | 示例 |
|------|------|------|
| `./gemini.sh start` | 启动专用浏览器（首次使用） | `./gemini.sh start &` |
| `./gemini.sh open` | 打开 Gemini（自动登录） | |
| `./gemini.sh chat "问题"` | 完整对话（提问+等待+滚动+提取） | `./gemini.sh chat "你好"` |
| `./gemini.sh image "提示词"` | 生成图片（需登录） | `./gemini.sh image "日落海滩"` |
| `./gemini.sh feishu` | 发送截图到飞书 | |
| `./gemini.sh extract` | 提取 Gemini 回复 | |
| `./gemini.sh screenshot` | 截图 | |
| `./gemini.sh stop` | 停止 MCP 服务器 | |
| `./gemini.sh status` | 检查服务器状态 | |

## 工作流示例

### 首次登录

```bash
# 后台启动专用浏览器
./gemini.sh start &

# 等待几秒，然后在浏览器中登录 Google
# 登录后按 Ctrl+C 停止服务器（状态已保存）
```

### 日常使用

```bash
# 打开并对话
./gemini.sh open                    # 打开 Gemini（自动登录）
./gemini.sh chat "Sora 2 的原理是什么？"

# 生成图片并发送
./gemini.sh image "一只三文鱼"       # 生成图片
./gemini.sh feishu                  # 发送到飞书
```

## 登录状态持久化

- **用户数据目录**: `~/.config/gemini-browser-profile/`
- 首次登录后，状态会保存在本地
- 之后每次打开自动登录，无需再次输入密码

## 注意事项

1. **首次使用**必须先 `./gemini.sh start` 并登录
2. **图片生成**需要 Gemini Advanced 订阅
3. **分享链接**有效期 7 天
4. **后台运行**：`./gemini.sh start &`
5. **停止服务器**：`./gemini.sh stop` 或 `Ctrl+C`
