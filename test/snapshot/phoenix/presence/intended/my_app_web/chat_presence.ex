defmodule MyAppWeb.ChatPresence do
  use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
  def track_user(socket, user_id, meta) do
    MyApp.Presence.track(self(), socket, user_id, meta)
  end
  def update_user(socket, user_id, meta) do
    MyApp.Presence.update(self(), socket, user_id, meta)
  end
  def untrack_user(socket, user_id) do
    MyApp.Presence.untrack(self(), socket, user_id)
  end
  def track_specific_pid(pid, user_id, meta) do
    MyApp.Presence.track(self(), pid, "users", user_id, meta)
  end
  def untrack_specific_pid(pid, user_id) do
    MyApp.Presence.untrack(self(), pid, "users", user_id)
  end
  def list_users(topic) do
    MyApp.Presence.list(topic)
  end
  def get_user_by_key(topic, key) do
    Phoenix.Presence.get_by_key(topic, key)
  end
end
