defmodule TestPubSub do
  def subscribe(topic) do
    {:ok, "subscribed to " <> topic}
  end
end
