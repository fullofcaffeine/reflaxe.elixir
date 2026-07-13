defmodule Main do
  def main() do
    socket = %{}
    MyAppWeb.Presence.track_user(socket, "user1", %{})
    MyAppWeb.Presence.track_user(socket, "user2", %{})
  end
end
