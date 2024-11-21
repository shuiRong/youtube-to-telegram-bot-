defmodule YouTubeBot.Downloader do
  require Logger

  @moduledoc """
  封装 youtubedr CLI 工具的所有调用
  """
  @doc """
  获取视频信息，包括标题、时长和原始输出。
  """
  def get_video_info(video_id) do
    case System.cmd("youtubedr", ["info", video_id]) do
      {output, 0} ->
        Logger.info("获取视频信息成功: #{output}")
        parse_video_info(output)

      {error, _} ->
        Logger.error("获取视频信息失败: #{error}")
        {:error, "获取视频信息失败"}
    end
  end

  defp parse_video_info(output) do
    with {:ok, title} <- extract_title(output),
         {:ok, duration} <- extract_duration(output) do
      {:ok, title, duration}
    end
  end

  defp extract_title(output) do
    case Regex.run(~r/Title:\s*(.+)\nAuthor:/, output) do
      [_, title] ->
        {:ok, String.trim(title)}

      nil ->
        Logger.error("获取视频标题失败: #{output}")
        {:ok, "video"}
    end
  end

  defp extract_duration(output) do
    case Regex.run(~r/Duration:\s*(\d+h)?(\d+m)?(\d+s)/, output) do
      [_, hours, minutes, seconds] ->
        total_seconds =
          parse_hours(hours) +
            parse_minutes(minutes) +
            parse_seconds(seconds)

        {:ok, total_seconds}

      nil ->
        Logger.error("获取视频时长失败: #{output}")
        {:ok, 0}
    end
  end

  defp parse_hours(hours) do
    hours
    |> String.trim_trailing("h")
    |> parse_number("小时")
    |> Kernel.*(3600)
  end

  defp parse_minutes(minutes) do
    minutes
    |> String.trim_trailing("m")
    |> parse_number("分钟")
    |> Kernel.*(60)
  end

  defp parse_seconds(seconds) do
    seconds
    |> String.trim_trailing("s")
    |> parse_number("秒")
  end

  defp parse_number(str, unit) do
    case Integer.parse(str) do
      {num, _} ->
        num

      :error ->
        Logger.warning("解析#{unit}失败: #{str}")
        0
    end
  end

  # 最大重试次数
  @max_retries 3
  # 重试延迟(毫秒)
  @retry_delay 1000

  def download_video_with_retry(file_path, video_id, temp_dir) do
    download_video(video_id, temp_dir, file_path, @max_retries)
  end

  defp download_video(video_id, temp_dir, file_path, retries_left) do
    Logger.info("开始下载视频: #{video_id}, 剩余重试次数: #{retries_left}")

    case System.cmd("youtubedr", [
           "download",
           "-d",
           temp_dir,
           "-o",
           "#{Path.basename(file_path)}",
           "-q",
           "139",
           video_id
         ]) do
      {_, 0} ->
        Logger.info("下载完成: #{file_path}")
        :ok

      {error, _} when retries_left > 0 ->
        Logger.info("下载失败，将在#{@retry_delay}ms后重试: #{error}")
        Process.sleep(@retry_delay)
        download_video(video_id, temp_dir, file_path, retries_left - 1)

      {error, _} ->
        Logger.error("下载失败，已无重试次数: #{error}")
        {:error, "下载失败,请稍后重试"}
    end
  end
end
