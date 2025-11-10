defmodule TodoAppWeb.Presence do
  use Phoenix.Presence, otp_app: :todo_app
  def track_user(socket, _user) do
    socket
  end
  def update_user_editing(socket, _user, _todo_id) do
    socket
  end
  def list_online_users(value) do
    __MODULE__.list("users")
  end
  def get_users_editing_todo(value, todo_id) do
    all_users = __MODULE__.list("users")
    Enum.reduce(Map.values(all_users), [], (fn -> fn entry, acc ->
      if (length(entry.metas) > 0) do
        meta = entry.metas[0]
        if (meta.editing_todo_id == todo_id) do
          Enum.concat(acc, [meta])
        else
          acc
        end
      else
        acc
      end
    end end).())
  end
  def track_internal(topic, key, meta) do
    __MODULE__.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    __MODULE__.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    __MODULE__.untrack(self(), topic, key)
  end
  def track_simple(key, meta) do
    __MODULE__.track(self(), "users", key, meta)
  end
  def update_simple(key, meta) do
    __MODULE__.update(self(), "users", key, meta)
  end
  def untrack_simple(key) do
    __MODULE__.untrack(self(), "users", key)
  end
  def list_simple() do
    __MODULE__.list("users")
  end
  def track_with_socket(socket, _topic, _key, _meta) do
    socket
  end
  def update_with_socket(socket, _topic, _key, _meta) do
    socket
  end
  def untrack_with_socket(socket, _topic, _key) do
    socket
  end
end
