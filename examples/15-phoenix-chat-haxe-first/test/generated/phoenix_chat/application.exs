defmodule PhoenixChat.Application do
  use Application
  def start(_type, _args) do
    dns_cluster_query = Application.get_env(:erlang.binary_to_atom("phoenix_chat"), :erlang.binary_to_atom("dns_cluster_query"), :erlang.binary_to_atom("ignore"))
    children = [PhoenixChatWeb.Telemetry, {DNSCluster, [query: dns_cluster_query]}, {Phoenix.PubSub, [name: PhoenixChat.PubSub]}, PhoenixChatWeb.Presence, PhoenixChatWeb.Endpoint]
    options = [strategy: :one_for_one, max_restarts: 3, max_seconds: 5]
    _ = Supervisor.start_link(children, options)
  end
end
