defmodule Phoenix.PubSubShim do
  def subscribe(pubsub, topic) do
    Phoenix.PubSub.subscribe(pubsub, topic)
  end
  def broadcast(pubsub, topic, message) do
    Phoenix.PubSub.broadcast_from(pubsub, self(), topic, message)
  end
end
