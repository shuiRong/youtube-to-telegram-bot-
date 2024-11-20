# YouTubeBot

A Telegram Bot that converts YouTube videos to MP3 format and sends them to a specified Telegram channel (the bot needs to be set as an administrator of that channel).

- Uses YouTube API to search for the latest videos from specific channels every hour. When new videos are detected, it automatically downloads and converts them to MP3 format, then sends them to the designated Telegram channel.
- The Telegram Bot can also receive YouTube video links from users and perform the same operations.

[中文版](README_ZH.md)

## Running Locally

### Prerequisites

1. Install Elixir environment
2. Download the command line tool: [youtubedr](https://github.com/kkrt-labs/youtubedr)
3. Configure environment variables:

   - `YOUTUBE_API_KEY`: Your YouTube API key
   - `YOUTUBE_CHANNEL_ID`: The YouTube channel ID you want to monitor
   - `TELEGRAM_BOT_TOKEN`: Your Telegram Bot Token
   - `BOT_CHANNEL_ID`: The Telegram channel ID you want to send the converted videos to
   - `BOT_WHITE_LIST`: Telegram user IDs allowed to use this Bot, separated by commas, to prevent unauthorized usage

### Getting Started

1. Clone the repository
   ```bash
   git clone git@github.com:shuiRong/youtube-to-telegram-bot.git
   cd youtube-to-telegram-bot
   ```
2. Install dependencies
   ```bash
   mix deps.get
   ```
3. Compile the project

   ```bash
   mix compile
   ```

4. Run in production mode

   ```bash
   MIX_ENV=prod mix run --no-halt
   ```

5. Testing
   - Send any message to your prepared Telegram Bot. If the Bot responds with any text, the program is running successfully
   - Send a YouTube video link to the Bot, and it will automatically download and convert it to MP3 format, then send it to the specified Telegram channel

### Tools Used

- [youtubedr](https://github.com/kkdai/youtube) tool for downloading MP3 format from YouTube videos
- [ExGram](https://github.com/rockneurotiko/ex_gram) library for interacting with Telegram API
- [Req](https://github.com/wojtekmach/req) HTTP client
- [Quantum](https://github.com/quantum-elixir/quantum-core): Job scheduler

## Contributing

Contributions are welcome! Please submit Pull Requests or raise issues.

## License

This project is licensed under the [MIT License](LICENSE).
