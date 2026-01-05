defmodule Main do
  def main() do
    socket = nil
    _ = TestAppWeb.Presence.track_test_user(socket, "user_1", "Alice")
    _ = TestAppWeb.Presence.update_status(socket, "user_1", "busy")
    _ = TestAppWeb.Presence.remove_user(socket, "user_1")
    _ = ExternalCaller.call_from_outside(socket)
    nil
  end
end
