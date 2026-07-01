defmodule TodoEvents do
  def encode(event) do
    (case event do
      {:toggle_todo, id} ->
        wire_payload = %{}
        wire_payload = Map.put(wire_payload, "id", id)
        %{event: "toggle_todo", payload: wire_payload}
      {:clipboard_copied, message} ->
        wire_payload = %{}
        wire_payload = Map.put(wire_payload, "message", message)
        %{event: "clipboard_copied", payload: wire_payload}
    end)
  end
  def decode(event_name, payload) do
    cond do
      event_name == "clipboard_copied" ->
        event_payload = if not Kernel.is_nil(payload) and Kernel.is_map(payload), do: payload, else: %{}
        message_raw = Map.get(event_payload, "message")
        message = if (Kernel.is_binary(message_raw)), do: message_raw, else: nil
        if not Kernel.is_nil(message), do: {:clipboard_copied, message}, else: nil
      event_name == "toggle_todo" ->
        event_payload = if not Kernel.is_nil(payload) and Kernel.is_map(payload), do: payload, else: %{}
        id_raw = Map.get(event_payload, "id")
        id = cond do
          Kernel.is_integer(id_raw) -> id_raw
          Kernel.is_binary(id_raw) ->
            (case Integer.parse(id_raw) do
              {num, _} -> num
              :error -> nil
            end)
          true -> nil
        end
        if not Kernel.is_nil(id), do: {:toggle_todo, id}, else: nil
      true -> nil
    end
  end
end
