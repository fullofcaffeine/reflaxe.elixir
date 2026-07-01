defmodule ProfileHookEvents do
  def encode(event) do
    (case event do
      {:clipboard_copied, message} ->
        wire_payload = %{}
        wire_payload = Map.put(wire_payload, "message", message)
        %{event: "clipboard_copied", payload: wire_payload}
      {:ping} ->
        wire_payload = %{}
        %{event: "ping", payload: wire_payload}
      {:todo_selected, todo_id, from_hook} ->
        wire_payload = %{}
        wire_payload = wire_payload |> Map.put("todo_id", todo_id) |> Map.put("from_hook", from_hook)
        %{event: "todo_selected", payload: wire_payload}
    end)
  end
  def decode(event_name, payload) do
    cond do
      event_name == "clipboard_copied" ->
        event_payload = if not Kernel.is_nil(payload) and Kernel.is_map(payload), do: payload, else: %{}
        message_raw = Map.get(event_payload, "message")
        message = if (Kernel.is_binary(message_raw)), do: message_raw, else: nil
        if not Kernel.is_nil(message), do: {:clipboard_copied, message}, else: nil
      event_name == "ping" -> {:ping}
      event_name == "todo_selected" ->
        event_payload = if not Kernel.is_nil(payload) and Kernel.is_map(payload), do: payload, else: %{}
        todo_id_raw = Map.get(event_payload, "todo_id")
        todo_id = if (Kernel.is_integer(todo_id_raw)), do: todo_id_raw, else: nil
        from_hook_raw = Map.get(event_payload, "from_hook")
        from_hook = if (Kernel.is_boolean(from_hook_raw)), do: from_hook_raw, else: nil
        if not Kernel.is_nil(todo_id) and not Kernel.is_nil(from_hook), do: {:todo_selected, todo_id, from_hook}, else: nil
      true -> nil
    end
  end
end
