defmodule YoutubeBot.Tasks do
  def your_hourly_task do
    # 在这里实现您想要每小时执行的逻辑
    IO.puts("执行定时任务...")
  end

  def your_1_seconds_task do
    # 在这里实现您想要每1秒钟执行的逻辑
    IO.puts("执行1秒定时任务...")
    YoutubeBot.youtube_search()
  end
end
