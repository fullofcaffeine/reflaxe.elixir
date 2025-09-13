defmodule Main do
  def main() do
    socket = %{}
    TestApp.Presence.track_test_user(socket, "user_1", "Alice")
    TestApp.Presence.update_status(socket, "user_1", "busy")
    TestApp.Presence.remove_user(socket, "user_1")
    ExternalCaller.call_from_outside(socket)
    Log.trace("PresenceMacro test completed successfully", %{:file_name => "Main.hx", :line_number => 119, :class_name => "Main", :method_name => "main"})
  end
end