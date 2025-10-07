defmodule MyAppWeb.ChatPresence do
  def track_user(socket, user_id, meta) do
    Presence.track(self(), socket, user_id, meta)
  end
  def update_user(socket, user_id, meta) do
    Presence.update(self(), socket, user_id, meta)
  end
  def untrack_user(socket, user_id) do
    Presence.untrack(self(), socket, user_id)
  end
  def track_specific_pid(pid, user_id, meta) do
    Presence.track(self(), pid, "users", user_id, meta)
  end
  def untrack_specific_pid(pid, user_id) do
    Presence.untrack(self(), pid, "users", user_id)
  end
  def list_users(topic) do
    Presence.list(topic)
  end
  def get_user_by_key(topic, key) do
    Presence.get_by_key(topic, key)
  end
end