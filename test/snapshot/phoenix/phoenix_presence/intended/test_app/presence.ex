defmodule TestApp.Presence do
  use Phoenix.Presence, otp_app: :test_app, pubsub_server: TestApp.PubSub
  def test_simple_track() do
    key = "user:123"
    meta = %{online_at: DateTime.to_unix(DateTime.utc_now(), :millisecond), status: "active"}
    TestApp.Presence.track(self(), "test:presence", key, meta)
  end
  def test_simple_update() do
    key = "user:123"
    meta = %{online_at: DateTime.to_unix(DateTime.utc_now(), :millisecond), status: "away"}
    TestApp.Presence.update(self(), "test:presence", key, meta)
  end
  def test_simple_untrack() do
    key = "user:123"
    TestApp.Presence.untrack(self(), "test:presence", key)
  end
  def test_chainable_methods(socket) do
    key = "user:456"
    meta = %{online_at: DateTime.to_unix(DateTime.utc_now(), :millisecond), device: "mobile"}
    TestApp.Presence.track(self(), "custom:topic", key, meta)
    meta = %{online_at: DateTime.to_unix(DateTime.utc_now(), :millisecond), device: "desktop"}
    TestApp.Presence.update(self(), "custom:topic", key, meta)
    TestApp.Presence.untrack(self(), "custom:topic", key)
    socket
  end
  def test_tracker_compatibility() do
    TestApp.Presence.track(self(), "test:presence", "critical:test", %{test: true})
    TestApp.Presence.update(self(), "test:presence", "critical:test", %{test: false})
    TestApp.Presence.untrack(self(), "test:presence", "critical:test")
  end
  def track_internal(topic, key, meta) do
    TestApp.Presence.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    TestApp.Presence.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    TestApp.Presence.untrack(self(), topic, key)
  end
  def track_simple(key, meta) do
    TestApp.Presence.track(self(), "test:presence", key, meta)
  end
  def update_simple(key, meta) do
    TestApp.Presence.update(self(), "test:presence", key, meta)
  end
  def untrack_simple(key) do
    TestApp.Presence.untrack(self(), "test:presence", key)
  end
  def list_simple() do
    TestApp.Presence.list("test:presence")
  end
  def track_with_socket(socket, topic, key, meta) do
    TestApp.Presence.track(self(), topic, key, meta)
    socket
  end
  def update_with_socket(socket, topic, key, meta) do
    TestApp.Presence.update(self(), topic, key, meta)
    socket
  end
  def untrack_with_socket(socket, topic, key) do
    TestApp.Presence.untrack(self(), topic, key)
    socket
  end
end
