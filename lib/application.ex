defmodule Nimble.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Nimble.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Nimble.PubSub},
      # Start the Endpoint (http/https)
      Nimble.Endpoint,
      {Finch, name: Swoosh.Finch}
      # Start a worker by calling: Nimble.Worker.start_link(arg)
      # {Nimble.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nimble.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Nimble.Endpoint.config_change(changed, removed)
    :ok
  end
end
