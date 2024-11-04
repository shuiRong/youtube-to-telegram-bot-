import Config

config :logger, level: :info

config :youtube_bot, YoutubeBot.Scheduler, debug_logging: false

config :youtube_bot, YoutubeBot.Scheduler,
  jobs: [
    # 每小时执行一次
    {"@hourly", {YoutubeBot.Tasks, :your_hourly_task, []}}
  ]

import_config "#{config_env()}.exs"
