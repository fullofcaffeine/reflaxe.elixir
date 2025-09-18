defmodule TodoAppWeb.Presence do
  def track_user(socket, user) do
    meta = %{:online_at => Date_Impl_.get_time(DateTime.utc_now()), :user_name => user.name, :user_email => user.email, :avatar => nil, :editing_todo_id => nil, :editing_started_at => nil}
    key = Std.string(user.id)
    Phoenix.Presence.track(self(), "users", key, meta)
    socket
  end
  def update_user_editing(socket, user, todo_id) do
    current_meta = TodoAppWeb.Presence.get_user_presence(socket, user.id)
    if (currentMeta == nil) do
      TodoAppWeb.Presence.track_user(socket, user)
    end
    temp_maybe_number = nil
    if (todoId != nil) do
      temp_maybe_number = Date_Impl_.get_time(DateTime.utc_now())
    else
      temp_maybe_number = nil
    end
    updated_meta = %{:online_at => currentMeta.online_at, :user_name => currentMeta.user_name, :user_email => currentMeta.user_email, :avatar => currentMeta.avatar, :editing_todo_id => todoId, :editing_started_at => tempMaybeNumber}
    key = Std.string(user.id)
    Phoenix.Presence.update(self(), "users", key, updatedMeta)
    socket
  end
  defp get_user_presence(socket, user_id) do
    presences = Phoenix.Presence.list("users")
    user_key = Std.string(userId)
    if (Map.has_key?(presences, String.to_atom(userKey))) do
      entry = Map.get(presences, String.to_atom(userKey))
      temp_result = nil
      if (length(entry.metas) > 0) do
        temp_result = entry.metas[0]
      else
        temp_result = nil
      end
      tempResult
    end
    nil
  end
  def list_online_users(socket) do
    Phoenix.Presence.list("users")
  end
  def get_users_editing_todo(socket, todo_id) do
    all_users = Phoenix.Presence.list("users")
    editing_users = []
    g = 0
    g1 = Map.keys(allUsers)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (g < length(g1)) do
    user_id = _g1[_g]
    g = g + 1
    entry = Map.get(allUsers, String.to_atom(userId))
    if (length(entry.metas) > 0) do
      meta = entry.metas[0]
      if (meta.editing_todo_id == todoId) do
        editingUsers = editingUsers ++ [meta]
      end
    end
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    editingUsers
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
  def list_simple() do
    Phoenix.Presence.list("users")
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