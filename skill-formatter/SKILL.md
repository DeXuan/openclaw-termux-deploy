---
name: wechat-article-formatter
description: 将技术内容（Markdown/笔记/代码/表格）一键转换为适配微信公众号编辑器的精美HTML文件，支持微信绿主题配色、深色代码块、警告/提示框、14类敏感信息自动脱敏。当用户要求发布/排版/格式化公众号文章、把技术文档转成公众号格式、或需要 Markdown 转微信 HTML 时使用。
---

# 微信公众号文章格式化

将任意技术内容转换为可直接粘贴到 https://mp.weixin.qq.com 编辑器的高质量 HTML 文件。

## 工作流

### 步骤 1：收集内容来源

确认用户的文章素材——可能是：
- 一篇已有 Markdown 文档（`Read` 读取）
- 本对话中讨论的技术方案和踩坑记录
- 用户口述的观点，由 Claude 扩展成文
- 混合来源（部分现成文档 + 部分新写）

### 步骤 2：生成文章

根据素材撰写/整理文章。遵循以下风格：

- **开篇有钩子**：一句话说清"这篇文章解决什么问题/实现什么效果"
- **技术深度适中**：面向有一定技术背景的读者，但不过于晦涩
- **干货前置**：好的对比表格、架构说明放在前面
- **章节标题用动词/问句**：避免抽象名词堆砌
- **末尾有闭环**：总结 + GitHub 链接 + 读者引导

### 步骤 3：敏感信息脱敏（必须执行）

用以下正则模式全局扫描全文，**全部替换为占位符**，绝不允许遗漏：

| 敏感类型 | 占位符 | 匹配模式 |
|---------|--------|---------|
| IPv4 地址 | `<手机IP>` / `<服务器IP>` | `\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}`（保留 127.0.0.1） |
| IPv6 地址 | `<IPv6地址>` | 长十六进制冒号分隔格式 |
| Tailscale IP | `<TS_IP>` | `100\.\d{1,3}\.\d{1,3}\.\d{1,3}` |
| API Key | `<YOUR_API_KEY>` | `sk-[a-zA-Z0-9]{20,}` |
| OAuth Token | `<YOUR_TOKEN>` | `gho_[a-zA-Z0-9]{30,}`、`ghp_[a-zA-Z0-9]{30,}` |
| Gateway Token | `<GATEWAY_TOKEN>` | 40 位十六进制字符串（独立出现不接在其他文本中） |
| QQ AppID | `<YOUR_APP_ID>` | 纯数字 9-10 位（出现在 `AppID`/`appId` 上下文） |
| AppSecret | `<YOUR_APP_SECRET>` | 32 位大小写字母数字混合（独立字段值） |
| 密码 | `<YOUR_PASSWORD>` | 出现在 `passwd`/`密码`/`password` 上下文 |
| 手机号 | `<手机号>` | 1[3-9]\d{9} |
| 设备序列号 | `<设备SN>` | 8 位十六进制（adb devices 输出格式） |
| 内网 IP 段 | `<内网IP>` | 192\.168\.\d{1,3}\.\d{1,3} |
| 蜂窝公网出口 IP | `<蜂窝出口IP>` | `39\.\d{1,3}\.\d{1,3}\.\d{1,3}` 等具体值 |
| WiFi MAC | `<MAC地址>` | `[0-9a-f]{2}:[0-9a-f]{2}:...` |

脱敏后做二次确认：用 `grep` 或逐段审视排查漏网之鱼。

### 步骤 4：生成 HTML

将脱敏后的 Markdown 转换为 HTML 文件。使用 [assets/template.html](assets/template.html) 作为骨架（拷贝 `<style>` 全部 CSS 和末尾闭合标签），按以下规则填充 `<body>`：

- `# 标题` → `<h1>`
- `## 二级` → `<h2>`（左侧绿边强调）
- `### 三级` → `<h3>`
- **加粗** → `<strong>`
- 代码块 → `<pre><code>`
- 行内代码 → `<code>`
- 表格 → `<table>`（带 `<tr><th>` 表头）
- 引用 → `<blockquote>`
- ⚠️ 警告 → `<p class="warn">`
- 💡 提示 → `<p class="tip">`
- 列表保持不变（Markdown 兼容 HTML）

**重要格式规则**：
- 代码块中的 `<` `>` `&` 必须转义为 `&lt;` `&gt;` `&amp;`
- `<pre>` 内的内容不额外加 `<p>` 标签
- 表格中如有 `<code>` 标签，用 `` 反引号替代以免嵌套混乱

### 步骤 5：输出到桌面并预览

保存为 `C:\Users\gdx\Desktop\<文章名>.html`，然后：

```bash
start "" "C:\Users\gdx\Desktop\<文章名>.html"
```

### 步骤 6：发布指引

提醒用户操作流程：
1. 浏览器 `Ctrl+A` → `Ctrl+C`
2. https://mp.weixin.qq.com → 新建图文 → `Ctrl+V`
3. 添加标题、封面图、文末引导关注
4. 预览 → 群发

同时提醒：微信编辑器可能洗掉 `<pre>` 深色背景（变成白底），代码仍可读。表格过宽时编辑器内手动调列宽。

## 样式系统

全部 CSS 已内置在 [assets/template.html](assets/template.html) 中，**每次生成 HTML 时直接复用其 `<style>...</style>` 完整内容**，不自行改动样式。

样式要点：
- 宽度 680px（公众号正文标准宽度）
- 二级标题左侧 `#07c160`（微信绿）4px 边线
- 代码块深色背景 `#2d2d2d` + 等宽字体 Consolas
- 警告框黄色 `#fff3cd` + 左侧橙色边线
- 提示框绿色 `#d4edda` + 左侧绿色边线
- 表格偶数行浅灰底色 `#fafafa`
- 手机端友好：16px 字号 + 1.8 行高 + PingFang SC 字体栈

## 参考

- [references/sanitize-checklist.md](references/sanitize-checklist.md) —— 14 类敏感信息的详细脱敏检查清单与正则表达式
- [assets/template.html](assets/template.html) —— 完整的 HTML 模板骨架（CSS + 结构）
