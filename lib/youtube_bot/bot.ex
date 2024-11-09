defmodule YouTubeBot.Bot do
  require Logger

  @bot :youtube_bot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  command("start")
  command("help", description: "Print the bot's help")

  middleware(ExGram.Middleware.IgnoreUsername)

  def bot(), do: @bot

  def handle({:command, :start, _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:command, :help, _msg}, context) do
    answer(context, "Here is your help")
  end

  # 处理用户消息
  def handle({:text, text, _msg}, context) do
    user_id = context.update.message.from.id
    whitelist = Application.fetch_env!(:youtube_bot, :bot_white_list)
    is_allowed = user_id in whitelist

    handle_text(text, context, is_allowed)
  end

  def handle_text(text, context, true) do
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
    answer(context, "您没有权限使用此Bot")
  end
end
