import Config

config :logger, level: :info, encoding: :utf8

config :youtube_bot, YouTubeBot.Scheduler, debug_logging: false

config :youtube_bot, YouTubeBot.Scheduler,
  jobs: [
    # 每小时执行一次
    {"@hourly", {YouTubeBot.Tasks, :your_hourly_task, []}}
    # {"@minutely", {YouTubeBot.Tasks, :your_hourly_task, []}}
  ]

import_config "#{config_env()}.exs"
