defmodule TodoAppWeb.Presence do
  use Phoenix.Presence, otp_app: :todo_app
  def track_user(socket, _user) do
    track(socket, "users", Std.string(user.id), (%{:online_at => Date_Impl_.get_time(DateTime.utc_now()), :user_name => user.name, :user_email => user.email, :avatar => nil, :editing_todo_id => nil, :editing_started_at => nil}))
  end
  def update_user_editing(socket, user, _todo_id) do
    current_meta = get_user_presence(socket, user.id)
    if (current_meta == nil), do: track_user(socket, user)
    updated_meta = %{:online_at => current_meta.online_at, :user_name => current_meta.user_name, :user_email => current_meta.user_email, :avatar => current_meta.avatar, :editing_todo_id => todo_id, :editing_started_at => if (todo_id != nil) do
  Date_Impl_.get_time(DateTime.utc_now())
else
  nil
end}
    update(socket, "users", Std.string(user.id), updated_meta)
  end
  defp get_user_presence(_socket, _user_id) do
    presences = list("users")
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
  def list_online_users(_socket) do
    list("users")
  end
  def get_users_editing_todo(_socket, _todo_id) do
    all_users = list("users")
    editing_users = []
    g = all_users.key_value_iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, :ok}, fn _, {acc_g, acc_state} -> nil end)
    editing_users
  end
end