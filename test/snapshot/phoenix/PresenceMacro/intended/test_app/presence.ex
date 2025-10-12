defmodule TestApp.Presence do
  use Phoenix.Presence, otp_app: :test_app
  def track_test_user(socket, user_id, name) do
    meta = %{:online_at => DateTime.to_iso8601(DateTime.utc_now()), :user_name => name, :status => "active"}
    MyAppWeb.Presence.track(self(), "presence:test", user_id, meta)
    socket
  end
  def update_status(socket, user_id, new_status) do
    presences = MyAppWeb.Presence.list("presence:test")
    if Map.has_key?(presences, user_id) do
      entry = Map.get(presences, user_id)
      if length(entry.metas) > 0 do
        current_meta = entry.metas[0]
        updated_meta = %{:online_at => current_meta.onlineAt, :user_name => current_meta.userName, :status => new_status}
        MyAppWeb.Presence.update(self(), "presence:test", user_id, updated_meta)
      end
    end
    socket
  end
  def remove_user(socket, user_id) do
    MyAppWeb.Presence.untrack(self(), "presence:test", user_id)
    socket
  end
  def track_with_socket(socket, topic, key, meta) do
    MyAppWeb.Presence.track(self(), topic, key, meta)
    socket
  end
  def update_with_socket(socket, topic, key, meta) do
    MyAppWeb.Presence.update(self(), topic, key, meta)
    socket
  end
  def untrack_with_socket(socket, topic, key) do
    MyAppWeb.Presence.untrack(self(), topic, key)
    socket
  end
end
