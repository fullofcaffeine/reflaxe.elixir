defmodule MyAppWeb.NormalModule do
  def track_from_outside(socket, user_id) do
    MyAppWeb.ChatPresence.track_user(socket, user_id, %{status: "outside"})
  end
  def update_from_outside(socket, user_id) do
    MyAppWeb.ChatPresence.update_user(socket, user_id, %{status: "updated"})
  end
  def list_from_outside() do
    MyAppWeb.ChatPresence.list_users()
  end
end
