defmodule TestApp.Presence do
  use Phoenix.Presence, otp_app: :test_app
  def track_test_user(socket, user_id, name) do
    meta = %{:online_at => Date_Impl_.get_time(DateTime.utc_now()), :user_name => name, :status => "active"}
    track_internal(socket, user_id, meta)
    socket
  end
  def update_status(socket, user_id, _new_status) do
    presences = list(socket)
    if (Reflect.has_field(presences, user_id)) do
      entry = Reflect.field(presences, user_id)
      if (length(entry.metas) > 0) do
        current_meta = entry.metas[0]
        updated_meta = %{:online_at => current_meta.online_at, :user_name => current_meta.user_name, :status => _new_status}
        update_internal(socket, user_id, updated_meta)
      end
    end
    socket
  end
  def remove_user(socket, user_id) do
    untrack_internal(socket, user_id)
    socket
  end
  def track_internal(socket, key, meta) do
    track(self(), socket, key, meta)
  end
  def update_internal(socket, key, meta) do
    update(self(), socket, key, meta)
  end
  def untrack_internal(socket, key) do
    untrack(self(), socket, key)
  end
  def track(socket, key, meta) do
    Phoenix.Presence.track(socket, key, meta)
  end
  def update(socket, key, meta) do
    Phoenix.Presence.update(socket, key, meta)
  end
  def untrack(socket, key) do
    Phoenix.Presence.untrack(socket, key)
  end
  def list(socket) do
    Phoenix.Presence.list(socket)
  end
  def get_by_key(socket, key) do
    Phoenix.Presence.get_by_key(socket, key)
  end
end