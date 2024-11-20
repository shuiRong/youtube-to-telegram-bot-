defmodule YouTubeBot.Tasks do
  def your_hourly_task do
    # 在这里实现您想要每小时执行的逻辑
    IO.puts("执行定时任务...")
    YouTubeBot.download_latest_videos()
  end
end
