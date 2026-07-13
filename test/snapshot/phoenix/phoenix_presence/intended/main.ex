defmodule Main do
  def main() do
    TestAppWeb.Presence.test_simple_track()
    TestAppWeb.Presence.test_simple_update()
    TestAppWeb.Presence.test_simple_untrack()
    TestAppWeb.Presence.test_tracker_compatibility()
    TestApp.LegacyPresence.test_legacy_methods()
    socket = %{}
    socket = TestAppWeb.Presence.test_chainable_methods(socket)
    socket
  end
end
