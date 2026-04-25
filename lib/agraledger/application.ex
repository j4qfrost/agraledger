defmodule Agraledger.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AgraledgerWeb.Telemetry,
      Agraledger.Repo,
      {DNSCluster, query: Application.get_env(:agraledger, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Agraledger.PubSub},
      # Start a worker by calling: Agraledger.Worker.start_link(arg)
      # {Agraledger.Worker, arg},
      # Start to serve requests, typically the last entry
      AgraledgerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Agraledger.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AgraledgerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
