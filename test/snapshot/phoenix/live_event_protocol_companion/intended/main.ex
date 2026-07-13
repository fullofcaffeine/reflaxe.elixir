defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    assert_that(true, "clipboard event constant failed")
    assert_that(true, "ping event constant failed")
    assert_that(true, "todo event constant failed")
    copied = ProfileHookEvents.encode({:clipboard_copied, "Copied."})
    assert_that(copied.event == "clipboard_copied", "clipboard encode event failed")
    copied_message = Map.get(copied.payload, "message")
    assert_that(Kernel.is_binary(copied_message) and Kernel.to_string(copied_message) == "Copied.", "clipboard encode payload failed")
    copied_decoded = ProfileHookEvents.decode("clipboard_copied", copied.payload)
    assert_that(not Kernel.is_nil(copied_decoded), "clipboard decode failed")
    selected_payload = Map.new()
    selected_payload = selected_payload |> Map.put("todo_id", 42) |> Map.put("from_hook", true)
    selected_decoded = ProfileHookEvents.decode("todo_selected", selected_payload)
    assert_that(not Kernel.is_nil(selected_decoded), "todo decode failed")
    invalid_payload = Map.new()
    assert_that(Kernel.is_nil(ProfileHookEvents.decode("clipboard_copied", invalid_payload)), "invalid payload should fail")
    assert_that(Kernel.is_nil(ProfileHookEvents.decode("unknown", invalid_payload)), "unknown event should fail")
  end
end
