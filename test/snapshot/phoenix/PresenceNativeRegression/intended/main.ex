defmodule Main do
  def main() do
    socket = %{}
    _ = MyAppWeb.Presence.track_user(socket, "user1", %{})
    _ = RegularPresence.track_user(socket, "user2", %{})
  end
end
