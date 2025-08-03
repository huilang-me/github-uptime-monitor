# 🌐 Website Uptime Monitor via GitHub Actions

一个无需服务器、完全基于 GitHub Actions 的轻量级网站状态监控器。

每 5 分钟定时检测网站是否在线，状态变化时通过 Telegram Bot 发送通知，并记录日志文件（按周保存，最多保留 5 周）。

---

## 🚀 功能特性

- ⏱️ 每 5 分钟自动运行
- 🔍 支持多个网站配置（通过 GitHub Secret 提供 JSON）
- ⚠️ 状态变化时自动通知 Telegram
- 🗂️ 日志按周记录，最多保留最近 5 周
- 🔐 所有敏感信息均使用 GitHub Secrets 安全管理

---

## ⚙️ 配置步骤

### 1. 创建 Telegram Bot 和 Chat ID

### 2. 设置 GitHub Secrets

在仓库 → `Settings` → `Secrets and variables` → `Actions` 添加以下 Secrets：

| 名称 | 说明 |
|------|------|
| `TELEGRAM_BOT_TOKEN` | Telegram Bot 的 Token |
| `TELEGRAM_CHAT_ID`   | 你接收通知的聊天 ID |
| `MONITOR_CONFIG_JSON` | 网站配置（JSON 格式字符串） |

📌 示例 `MONITOR_CONFIG_JSON`：IP可选

```json
[
  { "name": "example", "url": "https://example.com", "ip", "1.1.1.1" },
  { "name": "google", "url": "https://google.com" }
]
````

⚠️ 请粘贴为一行 JSON 字符串。

---

### 3. 日志结构（logs/monitor-YYYY-[WWW.json）](http://WWW.json）)

```json
[
  {
    "time": "2025-08-03 16:10:00",
    "name": "example",
    "status": "online"
  }
]
```

---

## 🛠️ 文件结构

```
.github/workflows/monitor.yml   # GitHub Actions 配置
monitor.sh                      # 状态检查脚本
status.json                     # 当前状态记录（自动更新）
logs/                           # 日志目录（按周分组）
```

---

## ✅ 启动监控

推送到 GitHub 后，GitHub Actions 会每 5 分钟自动运行。
你也可以在 Actions 页面手动点击运行。

你将收到如下 Telegram 提醒：

* ✅ example 网站状态变成『在线』
* ❌ google 网站状态变成『不在线』

---

## 🛡️ GitHub Actions 权限设置（重要）

若出现如下错误：

> `Permission to <your-repo> denied to github-actions[bot]`
> `fatal: unable to access ... error: 403`

这是因为 GitHub Actions 默认没有写入仓库的权限。

### ✅ 解决办法：

1. 打开你的仓库，进入 **Settings** → **Actions** → **General**
2. 找到 **Workflow permissions** 区域
3. 选择：

   * ✅ `Read and write permissions`
4. 点击下方的 **Save** 按钮
5. 回到 Actions 页面重新运行工作流即可

---

### 注意

Cloudflare开启防护的话，可能会被拦截，导致监控失败。

---

## 📜 License

MIT