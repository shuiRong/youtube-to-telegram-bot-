import Config

config :logger, level: :info

config :youtube_bot, YoutubeBot.Scheduler, debug_logging: false

config :youtube_bot, YoutubeBot.Scheduler,
  jobs: [
    # 每小时执行一次
    {"@hourly", {YoutubeBot.Tasks, :your_hourly_task, []}},
    # 每1秒钟执行一次
    {"@minutely", {YoutubeBot.Tasks, :your_1_seconds_task, []}}
  ]

config :youtube_bot, youtube_channel_id: "UC8UCbiPrm2zN9nZHKdTevZA"

import_config "#{config_env()}.exs"
