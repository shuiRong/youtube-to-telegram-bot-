defmodule YouTubeBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExGram,
      {YouTubeBot.Bot, [method: :polling, token: Application.fetch_env!(:ex_gram, :token)]},
      YouTubeBot.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: YouTubeBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
