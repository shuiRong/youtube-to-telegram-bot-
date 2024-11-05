# YoutubeBot

一个 Telegram Bot，用于将 YouTube 视频转换为 MP3 格式，然后发送到指定的（该频道需要把 Bot 设置为管理员） Telegram 频道。

- 利用 YouTube API，每小时搜索特定频道的最新视频，监测到有新视频后，自动下载并转换为 MP3 格式，然后发送到指定的 Telegram 频道。
- Telegram Bot 支持接收用户发送的 YouTube 视频链接，并进行相同的操作。

[English Version](README.md)

## 在本地运行本项目

### 前提条件

1. 安装 Elixir 环境
2. 提前下载好命令行工具：[youtubedr](https://github.com/kkrt-labs/youtubedr)
3. 配置环境变量：

   - `YOUTUBE_API_KEY`：你的 YouTube API 密钥
   - `YOUTUBE_CHANNEL_ID`：你要监控的 YouTube 频道 ID
   - `TELEGRAM_BOT_TOKEN`：你的 Telegram Bot Token
   - `BOT_CHANNEL_ID`：你要发送视频 MP3 的 Telegram 频道 ID
   - `BOT_WHITE_LIST`：允许使用该 Bot 的 Telegram 用户 ID，多个用英文逗号隔开，防止非授权用户使用

### 开始运行

1. 克隆仓库
   ```bash
   git clone git@github.com:shuiRong/youtube-to-telegram-bot.git
   cd youtube-to-telegram-bot
   ```
2. 安装依赖
   ```bash
   mix deps.get
   ```
3. 编译项目

   ```bash
   mix compile
   ```

4. 以生产模式运行

   ```bash
   MIX_ENV=prod mix run --no-halt
   ```

5. 测试效果
   - 发送任意消息到提前准备好的那个 Telegram Bot，Bot 如何返回了任何文字，则说明程序运行成功
   - 发送 YouTube 视频链接到 Bot，Bot 会自动下载并转换为 MP3 格式，然后发送到指定的 Telegram 频道

### 使用到的工具

- [youtubedr](https://github.com/kkdai/youtube) 工具从 YouTube 下载视频的 MP3 格式。
- [ExGram](https://github.com/rockneurotiko/ex_gram) 库与 Telegram API 交互。
- [Tesla](https://github.com/teamon/tesla)：HTTP 客户端
- [Quantum](https://github.com/quantum-elixir/quantum-core)：定时任务调度

## 贡献

欢迎贡献！请提交 Pull Request 或提出问题。

## 许可证

本项目采用 [MIT 许可证](LICENSE)。
