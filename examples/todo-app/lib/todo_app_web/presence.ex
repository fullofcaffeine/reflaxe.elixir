defmodule TodoAppWeb.Presence do
  use Phoenix.Presence, otp_app: :todo_app
  def track_user(socket, user) do
    meta = %{:online_at => Date_Impl_.get_time(DateTime.utc_now()), :user_name => user.name, :user_email => user.email, :avatar => nil, :editing_todo_id => nil, :editing_started_at => nil}
    key = Std.string(user.id)
    Phoenix.Presence.track(self(), "users", key, meta)
    socket
  end
  def update_user_editing(socket, user, todo_id) do
    current_meta = get_user_presence(socket, user.id)
    if (current_meta == nil), do: track_user(socket, user)
    updated_meta = %{:online_at => current_meta.online_at, :user_name => current_meta.user_name, :user_email => current_meta.user_email, :avatar => current_meta.avatar, :editing_todo_id => todo_id, :editing_started_at => if (todo_id != nil) do
  Date_Impl_.get_time(DateTime.utc_now())
else
  nil
end}
    key = Std.string(user.id)
    Phoenix.Presence.update(self(), "users", key, updated_meta)
    socket
  end
  defp get_user_presence(_socket, user_id) do
    presences = Phoenix.Presence.list("users")
    user_key = Std.string(user_id)
    if (Reflect.has_field(presences, user_key)) do
      entry = Reflect.field(presences, user_key)
      if (length(entry.metas) > 0) do
        entry.metas[0]
      else
        nil
      end
    end
    nil
  end
  def list_online_users(_socket) do
    Phoenix.Presence.list("users")
  end
  def get_users_editing_todo(_socket, todo_id) do
    all_users = Phoenix.Presence.list("users")
    editing_users = []
    g = 0
    g1 = Reflect.fields(all_users)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < length(acc_g1)) do
    user_id = acc_g1[acc_g]
    acc_g = acc_g + 1
    entry = Reflect.field(all_users, user_id)
    if (length(entry.metas) > 0) do
      meta = entry.metas[0]
      if (meta.editing_todo_id == todo_id) do
        editing_users = editing_users ++ [meta]
      end
    end
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    editing_users
  end
  def track_simple(key, meta) do
    Phoenix.Presence.track(self(), "users", key, meta)
  end
  def update_simple(key, meta) do
    Phoenix.Presence.update(self(), "users", key, meta)
  end
  def untrack_simple(key) do
    Phoenix.Presence.untrack(self(), "users", key)
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