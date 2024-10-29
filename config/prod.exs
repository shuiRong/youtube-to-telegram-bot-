import Config

IO.puts("config/runtime.exs")

config :youtube_bot,
  youtube_api_key: System.get_env("YOUTUBE_API_KEY")

config :ex_gram, token: System.get_env("TELEGRAM_BOT_TOKEN")
