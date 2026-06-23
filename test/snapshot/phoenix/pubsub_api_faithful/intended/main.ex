defmodule Main do
  def main() do

  end
  def subscribe_to_presence() do
    Phoenix.PubSub.subscribe(pubsub_module(), "presence:lobby")
  end
  def subscribe_with_options(options) do
    Phoenix.PubSub.subscribe(pubsub_module(), "presence:lobby", options)
  end
  def broadcast_message(payload) do
    Phoenix.PubSub.broadcast(pubsub_module(), "chat:lobby", payload)
  end
  def broadcast_message_from_self(payload) do
    Phoenix.PubSub.broadcast_from(pubsub_module(), Kernel.self(), "chat:lobby", payload)
  end
  def unsubscribe_from_presence() do
    Phoenix.PubSub.unsubscribe(pubsub_module(), "presence:lobby")
  end
  defp pubsub_module() do
    :erlang.binary_to_atom("Elixir.PhoenixChat.PubSub")
  end
end
