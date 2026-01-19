defmodule Main do
  def main() do
    _ = TestAppWeb.Presence.test_simple_track()
    _ = TestAppWeb.Presence.test_simple_update()
    _ = TestAppWeb.Presence.test_simple_untrack()
    _ = TestAppWeb.Presence.test_tracker_compatibility()
    _ = TestApp.LegacyPresence.test_legacy_methods()
    socket = %{}
    socket = TestAppWeb.Presence.test_chainable_methods(socket)
    socket
  end
end
