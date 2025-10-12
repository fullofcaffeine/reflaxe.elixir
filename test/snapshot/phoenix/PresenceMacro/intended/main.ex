defmodule Main do
  @compile {:nowarn_unused_function, [main: 0]}

  defp main() do
    socket = %{}
    MyAppWeb.Presence.track_test_user(socket, "user_1", "Alice")
    MyAppWeb.Presence.update_status(socket, "user_1", "busy")
    MyAppWeb.Presence.remove_user(socket, "user_1")
    MyApp.ExternalCaller.call_from_outside(socket)
    Log.trace("PresenceMacro test completed successfully", %{:file_name => "Main.hx", :line_number => 124, :class_name => "Main", :method_name => "main"})
  end
end
