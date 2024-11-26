defmodule YouTubeBot do
  require Logger

  @moduledoc """
  `YouTubeBot` 模块用于处理YouTube视频相关操作，如提取视频ID、获取视频信息和转换视频格式。
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

  def convert_to_mp3(video_id, channel_id) do
    YouTubeBot.Downloader.get_video_info(video_id)
    |> case do
      {:ok, title, duration, audio_id} ->
        System.tmp_dir!()
        |> Path.join("#{sanitize_filename(title)}.m4a")
        |> download_and_process(video_id, channel_id, title, duration, audio_id)

      {:error, reason} ->
        Logger.error("处理过程中出现错误: #{inspect(reason)}")
    end
  end

  @doc """
  将YouTube视频转换为MP3并发送给用户。

  ## 参数
    - `video_id`: 视频的ID
    - `channel_id`: 聊天ID，用于发送消息
    - `chat_id`: 聊天ID，用于发送消息
  """
  def convert_to_mp3(video_id, channel_id, chat_id) do
    YouTubeBot.Downloader.get_video_info(video_id)
    |> case do
      {:ok, title, duration, audio_id} ->
        System.tmp_dir!()
        |> Path.join("#{sanitize_filename(title)}.m4a")
        |> download_and_process(video_id, channel_id, title, duration, audio_id, chat_id)

      {:error, reason} ->
        Logger.error("处理过程中出现错误: #{inspect(reason)}")
        ExGram.send_message(chat_id, "处理过程中出现错误: #{inspect(reason)}")
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

  defp download_and_process(file_path, video_id, channel_id, title, duration, audio_id) do
    file_path
    |> YouTubeBot.Downloader.download_video_with_retry(video_id, audio_id, System.tmp_dir!())
    |> case do
      :ok ->
        send_file(file_path, channel_id, title, duration, audio_id)

      {:error, reason} ->
        Logger.error("处理过程中出现错误: #{inspect(reason)}")
    end
  end

  defp download_and_process(file_path, video_id, channel_id, title, duration, audio_id, chat_id) do
    file_path
    |> YouTubeBot.Downloader.download_video_with_retry(video_id, audio_id, System.tmp_dir!())
    |> case do
      :ok ->
        send_file(file_path, channel_id, title, duration, chat_id)

      {:error, reason} ->
        Logger.error("处理过程中出现错误: #{inspect(reason)}")
        ExGram.send_message(chat_id, "处理过程中出现错误: #{inspect(reason)}")
    end
  end

  defp send_file(file_path, channel_id, title, duration) do
    ExGram.send_audio(
      channel_id,
      {:file, file_path},
      caption: title,
      duration: duration
    )
    |> case do
      {:ok, _} ->
        Logger.info("文件发送成功: #{file_path}")
        File.rm(file_path)
        :ok

      {:error, reason} ->
        Logger.error("发送文件失败: #{inspect(reason)}")
        File.rm(file_path)
        {:error, reason}
    end
  end

  defp send_file(file_path, channel_id, title, duration, chat_id) do
    ExGram.send_audio(
      channel_id,
      {:file, file_path},
      caption: title,
      duration: duration
    )
    |> case do
      {:ok, _} ->
        Logger.info("文件发送成功: #{file_path}")
        File.rm(file_path)
        :ok

      {:error, reason} ->
        Logger.error("发送文件失败: #{inspect(reason)}")
        ExGram.send_message(chat_id, "发送文件失败: #{inspect(reason)}")
        File.rm(file_path)
        {:error, reason}
    end
  end

  defp sanitize_filename(filename) do
    filename
    |> String.replace(~r/[\/:*?"<>|]/, "_")
    |> String.trim()
  end

  def download_latest_videos() do
    fetch_latest_videos() |> handle_search_response()
  end

  def fetch_latest_videos() do
    Req.get!("https://www.googleapis.com/youtube/v3/search",
      params: [
        key: Application.fetch_env!(:youtube_bot, :youtube_api_key),
        channelId: Application.fetch_env!(:youtube_bot, :youtube_channel_id),
        part: "snippet,id",
        order: "date",
        type: "video",
        eventType: "completed",
        maxResults: 3
      ]
    ).body["items"]
  end

  defp handle_search_response(items) do
    items
    |> Enum.map(fn item ->
      %{
        title: item["snippet"]["title"],
        published_at: item["snippet"]["publishedAt"],
        video_id: item["id"]["videoId"]
      }
    end)
    |> filter_recent_videos()
    |> notify_and_convert()
  end

  defp filter_recent_videos(videos) do
    one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600, :second)
    IO.puts("one_hour_ago: #{one_hour_ago}")
    IO.puts("videos: #{inspect(videos)}")

    filtered_videos =
      videos
      |> Enum.filter(fn video ->
        {:ok, published_at, _} = DateTime.from_iso8601(video.published_at)
        IO.puts("published_at: #{published_at}")
        DateTime.compare(published_at, one_hour_ago) == :gt
      end)

    IO.puts("filtered_videos: #{inspect(filtered_videos)}")
    filtered_videos
  end

  defp notify_and_convert(recent_videos) when length(recent_videos) > 0 do
    Logger.info("发现 #{length(recent_videos)} 个新视频")

    recent_videos
    |> Enum.each(fn video ->
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

  defp notify_and_convert(_), do: :ok
end
