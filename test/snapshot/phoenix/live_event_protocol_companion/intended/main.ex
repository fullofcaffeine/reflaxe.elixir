defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    _ = assert_that(true, "clipboard event constant failed")
    _ = assert_that(true, "ping event constant failed")
    _ = assert_that(true, "todo event constant failed")
    copied = ProfileHookEvents.encode({:clipboard_copied, "Copied."})
    _ = assert_that(copied.event == "clipboard_copied", "clipboard encode event failed")
    _ = assert_that(Phoenix.Channels.WirePayload.get_string(copied.payload, "message") == "Copied.", "clipboard encode payload failed")
    copied_decoded = ProfileHookEvents.decode("clipboard_copied", copied.payload)
    _ = assert_that(not Kernel.is_nil(copied_decoded), "clipboard decode failed")
    selected_payload = %{}
    selected_payload = selected_payload |> Map.put("todo_id", 42) |> Map.put("from_hook", true)
    selected_decoded = ProfileHookEvents.decode("todo_selected", selected_payload)
    _ = assert_that(not Kernel.is_nil(selected_decoded), "todo decode failed")
    invalid_payload = %{}
    _ = assert_that(Kernel.is_nil(ProfileHookEvents.decode("clipboard_copied", invalid_payload)), "invalid payload should fail")
    _ = assert_that(Kernel.is_nil(ProfileHookEvents.decode("unknown", invalid_payload)), "unknown event should fail")
  end
end
