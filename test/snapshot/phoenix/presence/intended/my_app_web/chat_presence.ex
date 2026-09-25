defmodule MyAppWeb.ChatPresence do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def track_user(socket, user_id, meta) do
    topic = "users"
    key = user_id
    MyAppWeb.ChatPresence.track(self(), topic, key, meta)
    socket
  end
  def update_user(socket, user_id, meta) do
    topic = "users"
    key = user_id
    MyAppWeb.ChatPresence.update(self(), topic, key, meta)
    socket
  end
  def untrack_user(socket, user_id) do
    topic = "users"
    key = user_id
    MyAppWeb.ChatPresence.untrack(self(), topic, key)
    socket
  end
  def list_users() do
    topic = "users"
    MyAppWeb.ChatPresence.list(topic)
  end
  def get_user_by_key(key) do
    topic = "users"
    (case MyAppWeb.ChatPresence.get_by_key(topic, key) do [] -> nil; entry -> entry end)
  end
  def track_internal(topic, key, meta) do
    MyAppWeb.ChatPresence.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    MyAppWeb.ChatPresence.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    MyAppWeb.ChatPresence.untrack(self(), topic, key)
  end
  def track_with_socket(socket, topic, key, meta) do
    MyAppWeb.ChatPresence.track(self(), topic, key, meta)
    socket
  end
  def update_with_socket(socket, topic, key, meta) do
    MyAppWeb.ChatPresence.update(self(), topic, key, meta)
    socket
  end
  def untrack_with_socket(socket, topic, key) do
    MyAppWeb.ChatPresence.untrack(self(), topic, key)
    socket
  end
end
