defmodule Main do
  def main() do
    socket = nil
    TestAppWeb.Presence.track_test_user(socket, "user_1", "Alice")
    TestAppWeb.Presence.update_status(socket, "user_1", "busy")
    TestAppWeb.Presence.remove_user(socket, "user_1")
    ExternalCaller.call_from_outside(socket)
    nil
  end
end
