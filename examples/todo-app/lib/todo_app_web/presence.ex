defmodule TodoAppWeb.Presence do
  use Phoenix.Presence, otp_app: :todo_app
  def track_user(socket, user) do
    meta = %{:online_at => Date_Impl_.get_time(DateTime.utc_now()), :user_name => user.name, :user_email => user.email, :avatar => nil, :editing_todo_id => nil, :editing_started_at => nil}
    track_internal(socket, Std.string(user.id), meta)
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
    update_internal(socket, Std.string(user.id), updated_meta)
    socket
  end
  defp get_user_presence(socket, user_id) do
    presences = list(socket)
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
  def list_online_users(socket) do
    list(socket)
  end
  def get_users_editing_todo(socket, todo_id) do
    all_users = list(socket)
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