defmodule TestApp.Presence do
  def track_test_user(socket, user_id, name) do
    meta = %{:online_at => Date_Impl_.get_time(DateTime.utc_now()), :user_name => name, :status => "active"}
    Phoenix.Presence.track(self(), "presence:test", user_id, meta)
    socket
  end
  def update_status(socket, user_id, new_status) do
    presences = Phoenix.Presence.list("presence:test")
    if Map.has_key?(presences, user_id) do
      entry = Map.get(presences, user_id)
      if length(entry.metas) > 0 do
        current_meta = entry.metas[0]
        updated_meta = %{:online_at => current_meta.onlineAt, :user_name => current_meta.userName, :status => new_status}
        Phoenix.Presence.update(self(), "presence:test", user_id, updated_meta)
      end
    end
    socket
  end
  def remove_user(socket, user_id) do
    Phoenix.Presence.untrack(self(), "presence:test", user_id)
    socket
  end
  def track_with_socket(socket, topic, key, meta) do
    Phoenix.Presence.track(self(), topic, key, meta)
    socket
  end
  def update_with_socket(socket, topic, key, meta) do
    Phoenix.Presence.update(self(), topic, key, meta)
    socket
  end
  def untrack_with_socket(socket, topic, key) do
    Phoenix.Presence.untrack(self(), topic, key)
    socket
  end
end