defmodule TestApp.LegacyPresence do
  use Phoenix.Presence, otp_app: :test_app, pubsub_server: TestApp.PubSub
  def test_legacy_methods() do
    topic = "legacy:topic"
    key = "user:789"
    meta = %{status: "online"}
    _ = Phoenix.Presence.track(self(), topic, key, meta)
  end
  def track_internal(topic, key, meta) do
    TestApp.LegacyPresence.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    TestApp.LegacyPresence.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    TestApp.LegacyPresence.untrack(self(), topic, key)
  end
  def track_with_socket(socket, topic, key, meta) do
    TestApp.LegacyPresence.track(self(), topic, key, meta)
    socket
  end
  def update_with_socket(socket, topic, key, meta) do
    TestApp.LegacyPresence.update(self(), topic, key, meta)
    socket
  end
  def untrack_with_socket(socket, topic, key) do
    TestApp.LegacyPresence.untrack(self(), topic, key)
    socket
  end
end
