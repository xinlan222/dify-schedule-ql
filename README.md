# Dify 工作流定时调度脚本

一个轻量级的 Shell 脚本，用于定时调用 Dify 工作流 API，支持完整的日志记录和错误处理。

## ✨ 功能特性

- 🚀 **轻量级**：纯 Shell 脚本，无需额外依赖（除了 curl）
- 📝 **完整日志**：带时间戳、级别、颜色的日志输出
- 🔄 **日志轮转**：自动归档超过 10MB 的日志文件
- ⚙️ **灵活配置**：支持环境变量和 `.env` 配置文件
- 🛡️ **错误处理**：完善的前置检查和异常处理
- 📊 **响应保存**：自动保存每次 API 调用的响应
- 🎨 **友好输出**：终端彩色输出，易于查看

## 📦 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/xinlan222/dify-schedule-ql.git
cd dify-schedule-ql
```

### 2. 配置环境变量

复制配置文件模板：

```bash
cp .env.example .env
```

编辑 `.env` 文件，填写你的配置：

```bash
# Dify API 基础地址
DIFY_BASE_URL=http://your-dify-domain.com/v1

# Dify API 端点（工作流应用）
DIFY_API_ENDPOINT=/workflows/run

# Dify 工作流 API Token
DIFY_TOKEN=app-your-token-here

# 工作流输入参数（JSON 格式）
DIFY_INPUTS={"variable1":"value1"}

# 用户标识
DIFY_USER=root

# 响应模式（streaming 或 blocking）
DIFY_RESPONSE_MODE=streaming
```

### 3. 运行脚本

```bash
chmod +x dify-schedule.sh
./dify-schedule.sh
```

## 📋 配置说明

### 必填配置

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `DIFY_BASE_URL` | Dify API 基础地址 | `http://dify.example.com/v1` |
| `DIFY_TOKEN` | 工作流 API Token | `app-xxxxxxxxxx` |
| `DIFY_INPUTS` | 工作流输入参数（JSON） | `{"emails":"user@example.com"}` |

### 可选配置

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `DIFY_API_ENDPOINT` | API 端点路径 | `/workflows/run` |
| `DIFY_USER` | 用户标识 | `root` |
| `DIFY_RESPONSE_MODE` | 响应模式 | `streaming` |

### 如何获取 Dify Token

1. 登录 Dify 网站
2. 打开你的工作流应用
3. 点击右上角「API」按钮
4. 复制「API 密钥」

## ⏰ 配置定时任务

### Linux/macOS - 使用 crontab

编辑 crontab：

```bash
crontab -e
```

添加定时任务（每天早上 6:30 执行）：

```bash
30 6 * * * /path/to/dify-schedule.sh >> /path/to/logs/cron.log 2>&1
```

### Windows - 使用任务计划程序

1. 打开「任务计划程序」
2. 创建基本任务
3. 触发器：每天 6:30
4. 操作：启动程序
   - 程序：`bash.exe`（需要安装 Git Bash 或 WSL）
   - 参数：`/path/to/dify-schedule.sh`

### 常用 Cron 表达式

```bash
# 每天早上 6:30
30 6 * * *

# 每小时执行一次
0 * * * *

# 每天中午 12:00
0 12 * * *

# 每周一早上 9:00
0 9 * * 1

# 每月 1 号凌晨 2:00
0 2 1 * *
```

## 📊 日志说明

### 日志文件位置

- **主日志**：`./logs/dify-schedule.log`
- **响应文件**：`./logs/response_YYYYMMDD_HHMMSS.json`

### 日志格式

```
[2025-10-05 06:30:00] [INFO] ========== 开始执行 Dify 工作流 ==========
[2025-10-05 06:30:01] [SUCCESS] 依赖检查通过
[2025-10-05 06:30:02] [INFO] 发送 API 请求...
[2025-10-05 06:30:03] [INFO] HTTP 状态码: 200
[2025-10-05 06:30:03] [SUCCESS] API 调用成功
[2025-10-05 06:30:03] [SUCCESS] ========== 执行完成 ==========
```

### 日志级别

- `INFO`：一般信息
- `SUCCESS`：成功操作
- `WARN`：警告信息
- `ERROR`：错误信息

## 🔧 常见问题

### 1. HTTP 308 重定向错误

**问题**：API 调用返回 308 状态码

**原因**：API 地址配置不完整

**解决**：确保 `DIFY_BASE_URL` 和 `DIFY_API_ENDPOINT` 配置正确
- 基础地址：`http://your-domain.com/v1`
- 端点路径：`/workflows/run`

### 2. 邮件发送失败（550 Invalid User）

**问题**：Dify 工作流中的邮件节点失败

**原因**：
- 收件人邮箱地址格式错误
- SMTP 配置不正确

**解决**：
1. 检查收件人邮箱地址是否完整（如 `user@163.com`）
2. 确认 SMTP 服务已开启
3. 使用授权码而不是登录密码

### 3. curl 命令未找到

**问题**：脚本提示 `curl 命令未找到`

**解决**：安装 curl
```bash
# Ubuntu/Debian
sudo apt-get install curl

# CentOS/RHEL
sudo yum install curl

# macOS
brew install curl
```

### 4. 权限不足

**问题**：脚本无法执行

**解决**：添加执行权限
```bash
chmod +x dify-schedule.sh
```

### 5. 私有化部署无法访问

**问题**：Dify 是私有化部署，外网无法访问

**解决方案**：
- 在部署 Dify 的服务器上运行脚本
- 或配置内网穿透（frp、ngrok 等）
- 或使用 VPN 连接到内网

## 🔍 调试技巧

### 查看详细日志

```bash
# 实时查看日志
tail -f logs/dify-schedule.log

# 查看最近 50 行日志
tail -n 50 logs/dify-schedule.log

# 搜索错误日志
grep ERROR logs/dify-schedule.log
```

### 手动测试 API

```bash
curl -X POST 'http://your-domain.com/v1/workflows/run' \
  --header 'Authorization: Bearer your-token' \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "inputs": {},
    "response_mode": "blocking",
    "user": "test"
  }'
```

## 📄 许可证

[MIT License](./LICENSE)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📧 联系方式

如有问题，请提交 [GitHub Issue](https://github.com/xinlan222/dify-schedule-ql/issues)

