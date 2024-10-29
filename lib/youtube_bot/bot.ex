defmodule YoutubeBot.Bot do
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
    answer(context, "Hi!112")
  end

  def handle({:command, :help, _msg}, context) do
    answer(context, "Here is your help:")
  end

  def handle({:text, text, _msg}, context) do
    case YoutubeBot.get_video_id(text) do
      {:ok, video_id} ->
        YoutubeBot.convert_to_mp3(video_id, context.update.message.chat.id)

      {:error, _} ->
        answer(context, "无效的YouTube链接")
    end
  end
end
