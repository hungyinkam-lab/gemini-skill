# Gemini Skill for OpenClaw

通过 OpenClaw 与 Google Gemini 对话，支持登录状态持久化。

## 快速开始

### 1. 安装依赖

```bash
# 安装 mcporter
npm install -g mcporter

# 安装 playwright-cli
npm install -g playwright
```

### 2. 启动 MCP 服务器

```bash
cd skills/playwright-mcp
./playwright.sh start
```

### 3. 使用 Gemini

```bash
cd skills/gemini

# 首次登录（只需一次）
./gemini.sh start

# 日常使用
./gemini.sh open           # 打开 Gemini
./gemini.sh chat "你好"    # 对话
./gemini.sh image "三文鱼" # 生成图片
```

## 文档

详细说明请查看 [SKILL.md](SKILL.md)

## GitHub

https://github.com/hungyinkam-lab/gemini-skill
