defmodule ProfileHookEvents do
  def encode(event) do
    (case event do
      {:clipboard_copied, payload} ->
        wire_payload = %{}
        wire_payload = wire_payload |> Map.put("copied_at", payload.copied_at) |> Map.put("message", payload.message)
        %{event: "clipboard_copied", payload: wire_payload}
      {:ping} ->
        wire_payload = %{}
        %{event: "ping", payload: wire_payload}
    end)
  end
  def decode(event_name, payload) do
    cond do
      event_name == "clipboard_copied" ->
        event_payload = if not Kernel.is_nil(payload) and Kernel.is_map(payload), do: payload, else: %{}
        copied_at_raw = Map.get(event_payload, "copied_at")
        copied_at = if (Kernel.is_binary(copied_at_raw)), do: copied_at_raw, else: nil
        message_raw = Map.get(event_payload, "message")
        message = if (Kernel.is_binary(message_raw)), do: message_raw, else: nil
        if not Kernel.is_nil(copied_at) and not Kernel.is_nil(message), do: {:clipboard_copied, %{copied_at: copied_at, message: message}}, else: nil
      event_name == "ping" -> {:ping}
      true -> nil
    end
  end
end
