defmodule YouTubeBot.Bot do
  require Logger

  @bot :youtube_bot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  command("start")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  def handle({:command, :start, _msg}, context) do
    answer(
      context,
      "Hi! This bot is for demo only. It's open source, please visit https://github.com/shuiRong/youtube-to-telegram-bot-elixir for more information."
    )
  end

  # 处理用户消息
  def handle({:text, text, _msg}, context) do
    user_id = context.update.message.from.id
    whitelist = Application.fetch_env!(:youtube_bot, :bot_white_list)
    is_allowed = user_id in whitelist

    handle_text(text, context, is_allowed)
  end

  def handle_text(text, context, true) do
    answer(context, "收到请求，开始处理...")

    case YouTubeBot.get_video_id(text) do
      {:ok, video_id} ->
        YouTubeBot.convert_to_mp3(
          video_id,
          Application.fetch_env!(:youtube_bot, :bot_channel_id),
          context.update.message.chat.id
        )

      {:error, _} ->
        answer(context, "无效的YouTube链接")
    end
  end

  def handle_text(_text, context, false) do
    answer(
      context,
      "This bot is for demo only. It's open source, please visit https://github.com/shuiRong/youtube-to-telegram-bot-elixir for more information."
    )
  end
end
