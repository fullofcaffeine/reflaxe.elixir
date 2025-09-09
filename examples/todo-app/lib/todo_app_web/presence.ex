defmodule TodoAppWeb.Presence do
  use Phoenix.Presence, otp_app: :todo_app
  def track_user(socket, user) do
    meta = %{:online_at => _this = Date.now()
DateTime.to_unix(this.datetime, :millisecond), :user_name => user.name, :user_email => user.email, :avatar => nil, :editing_todo_id => nil, :editing_started_at => nil}
    track(socket, "users", Std.string(user.id), meta)
  end
  def update_user_editing(socket, user, todo_id) do
    current_meta = get_user_presence(socket, user.id)
    if (current_meta == nil), do: track_user(socket, user)
    updated_meta = %{:online_at => current_meta.online_at, :user_name => current_meta.user_name, :user_email => current_meta.user_email, :avatar => current_meta.avatar, :editing_todo_id => todo_id, :editing_started_at => if (todo_id != nil) do
  _this = Date.now()
  DateTime.to_unix(this.datetime, :millisecond)
else
  nil
end}
    update(socket, "users", Std.string(user.id), updated_meta)
  end
  defp get_user_presence(socket, user_id) do
    presences = list(socket, "users")
    user_key = Std.string(user_id)
    if (Map.has_key?(presences, user_key)) do
      entry = Map.get(presences, user_key)
      if (length(entry.metas) > 0) do
        entry.metas[0]
      else
        nil
      end
    end
    nil
  end
  def list_online_users(socket) do
    list(socket, "users")
  end
  def get_users_editing_todo(socket, todo_id) do
    all_users = list(socket, "users")
    editing_users = []
    g = all_users.key_value_iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, :ok}, fn _, {acc_g, acc_state} -> nil end)
    editing_users
  end
end