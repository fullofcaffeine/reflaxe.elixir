defmodule TestApp.Presence do
  use Phoenix.Presence, otp_app: :test_app, pubsub_server: TestApp.PubSub
  def track_user_live_view(socket, user_id, user_name) do
    meta = %{:online_at => DateTime.to_iso8601(DateTime.utc_now()), :user_name => user_name, :status => "active"}
    TestApp.Presence.track(self(), "presence:test", user_id, meta)
    socket
  end
  def track_user_custom(socket, user_id, user_name) do
    meta = %{:online_at => DateTime.to_iso8601(DateTime.utc_now()), :user_name => user_name}
    TestApp.Presence.track(self(), "presence:test", user_id, meta)
    socket
  end
  def track_with_anonymous(socket, key) do
    meta = %{:timestamp => DateTime.to_iso8601(DateTime.utc_now()), :source => "test"}
    TestApp.Presence.track(self(), "presence:test", key, meta)
    socket
  end
  def update_user_status(socket, user_id, new_status) do
    meta = %{:online_at => DateTime.to_iso8601(DateTime.utc_now()), :user_name => "test", :status => new_status}
    TestApp.Presence.update(self(), "presence:test", user_id, meta)
    socket
  end
  def remove_user(socket, user_id) do
    TestApp.Presence.untrack(self(), "presence:test", user_id)
    socket
  end
  def get_all_users(_socket) do
    TestApp.Presence.list("presence:test")
  end
  def find_user(_socket, user_id) do
    (case TestApp.Presence.get_by_key("presence:test", user_id) do [] -> nil; entry -> entry end)
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
