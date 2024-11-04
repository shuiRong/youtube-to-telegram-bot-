import Config

IO.puts("config/runtime.exs")

config :youtube_bot,
  youtube_api_key: System.get_env("YOUTUBE_API_KEY")

config :ex_gram, token: System.get_env("TELEGRAM_BOT_TOKEN")

config :youtube_bot, youtube_channel_id: System.get_env("YOUTUBE_CHANNEL_ID")

config :youtube_bot,
  bot_white_list:
    System.get_env("BOT_WHITE_LIST") |> String.split(",") |> Enum.map(&String.to_integer/1)
