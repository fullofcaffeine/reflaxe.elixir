defmodule TodoAppWeb.Presence do
  use Phoenix.Presence, otp_app: :todo_app
  def track_user(socket, user) do
    meta = %{:onlineAt => DateTime.utc_now() |> DateTime.to_unix(:millisecond), :userName => user.name, :userEmail => user.email, :avatar => nil, :editingTodoId => nil, :editingStartedAt => nil}
    Phoenix.Presence.track(socket, "users", Std.string(user.id), meta)
  end
  def update_user_editing(socket, user, todo_id) do
    current_meta = TodoAppWeb.Presence.get_user_presence(socket, user.id)
    if (current_meta == nil) do
      TodoAppWeb.Presence.track_user(socket, user)
    end
    updated_meta = %{:onlineAt => current_meta.onlineAt, :userName => current_meta.userName, :userEmail => current_meta.userEmail, :avatar => current_meta.avatar, :editingTodoId => todo_id, :editingStartedAt => if (todo_id != nil) do
  DateTime.utc_now() |> DateTime.to_unix(:millisecond)
else
  nil
end}
    Phoenix.Presence.update(socket, "users", Std.string(user.id), updated_meta)
  end
  defp get_user_presence(socket, user_id) do
    presences = Phoenix.Presence.list(socket, "users")
    user_key = Std.string(user_id)
    if (Map.has_key?(presences, user_key)) do
      entry = Map.get(presences, user_key)
      if (entry.metas.length > 0) do
        entry.metas[0]
      else
        nil
      end
    end
    nil
  end
  def list_online_users(socket) do
    Phoenix.Presence.list(socket, "users")
  end
  def get_users_editing_todo(socket, todo_id) do
    all_users = Phoenix.Presence.list(socket, "users")
    editing_users = []
    g = all_users.keyValueIterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, :ok}, fn _, {acc_g, acc_state} ->
  if (acc_g.hasNext()) do
    _user_id = acc_g.key
    entry = acc_g.value
    if (entry.metas.length > 0) do
      meta = entry.metas[0]
      if (meta.editingTodoId == todo_id), do: editing_users ++ [meta]
    end
    {:cont, {acc_g, acc_state}}
  else
    {:halt, {acc_g, acc_state}}
  end
end)
    editing_users
  end
end