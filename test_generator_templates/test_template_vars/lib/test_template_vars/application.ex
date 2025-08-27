defmodule TestTemplateVars.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TestTemplateVarsWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:test_template_vars, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TestTemplateVars.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TestTemplateVars.Finch},
      # Start a worker by calling: TestTemplateVars.Worker.start_link(arg)
      # {TestTemplateVars.Worker, arg},
      # Start to serve requests, typically the last entry
      TestTemplateVarsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TestTemplateVars.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TestTemplateVarsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
