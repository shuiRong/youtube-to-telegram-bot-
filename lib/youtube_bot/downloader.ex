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
         {:ok, duration} <- extract_duration(output),
         {:ok, audio_id} <- extract_audio_id(output) do
      {:ok, title, duration, audio_id}
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

  # 提取可用的音频ID
  # Title:       川普关税迫使中国工厂出走东南亚/澳大利亚留学生流行打工/王剑每日观察/20241121
  # Author:      王剑每日观察Kim's Observation
  # Duration:    1h7m18s

  # +------+-----+---------+----------+----------+-----------+---------+--------------------------------------------+----------+
  # | ITAG | FPS |  VIDEO  |  AUDIO   |  AUDIO   | SIZE [MB] | BITRATE |                  MIMETYPE                  | LANGUAGE |
  # |      |     | QUALITY | QUALITY  | CHANNELS |           |         |                                            |          |
  # +------+-----+---------+----------+----------+-----------+---------+--------------------------------------------+----------+
  # |  137 |  30 | 1080p   |          |        0 |     749.9 | 1558142 | video/mp4; codecs="avc1.640028"            |          |
  # |  248 |  30 | 1080p   |          |        0 |     425.4 |  883920 | video/webm; codecs="vp9"                   |          |
  # |  136 |  30 | 720p    |          |        0 |     424.2 |  881349 | video/mp4; codecs="avc1.64001f"            |          |
  # |  247 |  30 | 720p    |          |        0 |     285.5 |  593328 | video/webm; codecs="vp9"                   |          |
  # |  135 |  30 | 480p    |          |        0 |     225.4 |  468448 | video/mp4; codecs="avc1.4d401f"            |          |
  # |  244 |  30 | 480p    |          |        0 |     114.8 |  238446 | video/webm; codecs="vp9"                   |          |
  # |  134 |  30 | 360p    |          |        0 |     118.0 |  245261 | video/mp4; codecs="avc1.4d401e"            |          |
  # |   18 |  30 | 360p    | low      |        2 |     140.9 |  292798 | video/mp4; codecs="avc1.42001E, mp4a.40.2" |          |
  # |  243 |  30 | 360p    |          |        0 |      75.7 |  157360 | video/webm; codecs="vp9"                   |          |
  # |  133 |  30 | 240p    |          |        0 |      62.3 |  129408 | video/mp4; codecs="avc1.4d4015"            |          |
  # |  242 |  30 | 240p    |          |        0 |      43.4 |   90152 | video/webm; codecs="vp9"                   |          |
  # |  140 |   0 |         | medium   |        2 |      62.3 |  129472 | audio/mp4; codecs="mp4a.40.2"              |          |
  # |  140 |   0 |         | medium   |        2 |      62.3 |  129472 | audio/mp4; codecs="mp4a.40.2"              |          |
  # |  251 |   0 |         | medium   |        2 |      53.9 |  111937 | audio/webm; codecs="opus"                  |          |
  # |  251 |   0 |         | medium   |        2 |      53.6 |  111292 | audio/webm; codecs="opus"                  |          |
  # |  160 |  30 | 144p    |          |        0 |      28.9 |   60055 | video/mp4; codecs="avc1.4d400c"            |          |
  # |  278 |  30 | 144p    |          |        0 |      24.9 |   51755 | video/webm; codecs="vp9"                   |          |
  # |  250 |   0 |         | low      |        2 |      30.1 |   62597 | audio/webm; codecs="opus"                  |          |
  # |  250 |   0 |         | low      |        2 |      30.0 |   62340 | audio/webm; codecs="opus"                  |          |
  # |  249 |   0 |         | low      |        2 |      23.8 |   49387 | audio/webm; codecs="opus"                  |          |
  # |  249 |   0 |         | low      |        2 |      23.2 |   48236 | audio/webm; codecs="opus"                  |          |
  # |  598 |  15 | 144p    |          |        0 |      14.2 |   29551 | video/webm; codecs="vp9"                   |          |
  # |  597 |  15 | 144p    |          |        0 |      14.5 |   30049 | video/mp4; codecs="avc1.4d400b"            |          |
  # |  600 |   0 |         | ultralow |        2 |      16.3 |   33814 | audio/webm; codecs="opus"                  |          |
  # |  600 |   0 |         | ultralow |        2 |      15.9 |   33116 | audio/webm; codecs="opus"                  |          |
  # |  599 |   0 |         | ultralow |        2 |      14.8 |   30784 | audio/mp4; codecs="mp4a.40.5"              |          |
  # |  599 |   0 |         | ultralow |        2 |      14.8 |   30784 | audio/mp4; codecs="mp4a.40.5"              |          |
  # +------+-----+---------+----------+----------+-----------+---------+--------------------------------------------+----------+
  defp extract_audio_id(output) do
    # 提取所有音频的itag和大小
    audio_info =
      Regex.scan(~r/\|\s+(\d+)\s+\|.*\|\s+(\d+\.?\d*)\s+\|\s+\d+\s+\|\s+audio\/.*\|/, output)
      |> Enum.map(fn [_, itag, size] ->
        {itag, String.to_float(size)}
      end)

    case audio_info do
      [] ->
        Logger.error("未找到可用的音频格式")
        {:error, "未找到可用的音频格式"}

      info ->
        # 按大小排序并返回最小的itag
        {itag, _} = Enum.min_by(info, fn {_, size} -> size end)
        {:ok, itag}
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

  def download_video_with_retry(file_path, video_id, audio_id, temp_dir) do
    download_video(video_id, temp_dir, file_path, audio_id, @max_retries)
  end

  defp download_video(video_id, temp_dir, file_path, audio_id, retries_left) do
    Logger.info("开始下载视频: #{video_id}, 剩余重试次数: #{retries_left}")

    case System.cmd("youtubedr", [
           "download",
           "-d",
           temp_dir,
           "-o",
           "#{Path.basename(file_path)}",
           "-q",
           audio_id || "139",
           video_id
         ]) do
      {_, 0} ->
        Logger.info("下载完成: #{file_path}")
        :ok

      {error, reason} when retries_left > 0 ->
        Logger.info("下载失败，将在#{@retry_delay}ms后重试: #{error} #{inspect(reason)}")
        Process.sleep(@retry_delay)
        download_video(video_id, temp_dir, file_path, audio_id, retries_left - 1)

      {error, _} ->
        Logger.error("下载失败，已无重试次数: #{error}")
        {:error, "下载失败,请稍后重试"}
    end
  end
end
