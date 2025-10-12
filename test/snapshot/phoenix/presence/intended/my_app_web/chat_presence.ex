defmodule MyAppWeb.ChatPresence do
  use Phoenix.Presence, otp_app: :my_app
  def track_user(socket, user_id, meta) do
    MyAppWeb.Presence.track(self(), socket, user_id, meta)
  end
  def update_user(socket, user_id, meta) do
    MyAppWeb.Presence.update(self(), socket, user_id, meta)
  end
  def untrack_user(socket, user_id) do
    MyAppWeb.Presence.untrack(self(), socket, user_id)
  end
  def track_specific_pid(pid, user_id, meta) do
    MyAppWeb.Presence.track(self(), pid, "users", user_id, meta)
  end
  def untrack_specific_pid(pid, user_id) do
    MyAppWeb.Presence.untrack(self(), pid, "users", user_id)
  end
  def list_users(topic) do
    MyAppWeb.Presence.list(topic)
  end
  def get_user_by_key(topic, key) do
    MyAppWeb.Presence.get_by_key(topic, key)
  end
end
