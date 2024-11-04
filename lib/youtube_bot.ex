defmodule YoutubeBot do
  require Logger

  @moduledoc """
  `YoutubeBot` 模块用于处理YouTube视频相关操作，如提取视频ID、获取视频信息和转换视频格式。
  """
  @doc """
  从 YouTube 链接中提取视频 ID。支持以下格式：
  - 标准链接：https://www.youtube.com/watch?v=7y8eotcYgy0&t=3s
  - 短链接：https://youtu.be/u5uUukAi_8I?si=M4eComOtkCQNQaIL&t=36
  """
  def get_video_id(url) do
    cond do
      String.starts_with?(url, "https://www.youtube.com/watch?v=") ->
        url
        |> String.replace("https://www.youtube.com/watch?v=", "")
        |> extract_parameter("&")

      String.starts_with?(url, "https://youtu.be/") ->
        url
        |> String.replace("https://youtu.be/", "")
        |> extract_parameter("?")

      String.starts_with?(url, "https://www.youtube.com/live/") ->
        url
        |> String.replace("https://www.youtube.com/live/", "")
        |> extract_parameter("?")

      true ->
        {:error, "无效的YouTube链接"}
    end
  end

  defp extract_parameter(rest, delimiter) do
    rest
    |> String.split(delimiter, parts: 2, trim: true)
    |> List.first()
    |> case do
      nil -> {:error, "无效的YouTube链接格式"}
      video_id -> {:ok, video_id}
    end
  end

  @doc """
  将YouTube视频转换为MP3并发送给用户。

  ## 参数
    - `video_id`: 视频的ID
    - `context`: 上下文信息，用于发送消息
  """
  def convert_to_mp3(video_id, chat_id) do
    with {:ok, title, duration, _output} <- YoutubeBot.Client.get_video_info(video_id),
         temp_dir = System.tmp_dir!(),
         file_path = Path.join(temp_dir, "#{sanitize_filename(title)}.m4a"),
         :ok <- YoutubeBot.Client.download_video_with_retry(video_id, temp_dir, file_path),
         :ok <- send_file(chat_id, file_path, title, duration) do
      :ok
    else
      {:error, reason} ->
        Logger.error("处理过程中出现错误: #{inspect(reason)}")
        ExGram.send_message(chat_id, "处理过程中出现错误，请稍后重试")
    end
  end

  defp send_file(chat_id, file_path, title, duration) do
    case ExGram.send_audio(
           chat_id,
           {:file, file_path},
           caption: title,
           duration: duration
         ) do
      {:ok, _} ->
        Logger.info("文件发送成功")
        File.rm(file_path)
        :ok

      {:error, reason} ->
        Logger.error("发送文件失败: #{inspect(reason)}")
        ExGram.send_message(chat_id, "发送文件失败,请稍后重试")
        File.rm(file_path)
        {:error, reason}
    end
  end

  defp sanitize_filename(filename) do
    filename
    |> String.replace(~r/[\/:*?"<>|]/, "_")
    |> String.trim()
  end

  defp client do
    Tesla.client([
      {Tesla.Middleware.Retry, delay: 1000, max_retries: 3},
      Tesla.Middleware.Logger,
      Tesla.Middleware.JSON
    ])
  end

  def youtube_search() do
    api_key = Application.fetch_env!(:youtube_bot, :youtube_api_key)
    url = "https://www.googleapis.com/youtube/v3/search"

    query = [
      key: api_key,
      channelId: Application.fetch_env!(:youtube_bot, :youtube_channel_id),
      part: "snippet,id",
      order: "date",
      type: "video",
      eventType: "completed",
      maxResults: 3
    ]

    case Tesla.get(client(), url, query: query) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        videos =
          body["items"]
          |> Enum.map(fn item ->
            %{
              title: item["snippet"]["title"],
              published_at: item["snippet"]["publishedAt"],
              video_id: item["id"]["videoId"]
            }
          end)

        one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600, :second)

        recent_videos =
          Enum.filter(videos, fn video ->
            {:ok, published_at, _} = DateTime.from_iso8601(video.published_at)
            DateTime.compare(published_at, one_hour_ago) == :gt
          end)

        if length(recent_videos) > 0 do
          Logger.info("发现 #{length(recent_videos)} 个新视频")

          Enum.each(recent_videos, fn video ->
            Logger.info("""
            处理新视频:
            标题: #{video.title}
            发布时间: #{video.published_at}
            视频ID: #{video.video_id}
            ---
            """)

            convert_to_mp3(video.video_id, -1_002_053_570_560)
          end)
        end

        {:ok, videos}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("YouTube API 返回错误: #{status}, #{inspect(body)}")
        {:error, "API 请求失败: #{status}"}

      {:error, reason} ->
        Logger.error("YouTube API 请求失败: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
