defmodule ProfileHookEvents do
  def encode(event) do
    (case event do
      {:clipboard_copied, message} ->
        wire_payload = %{}
        wire_payload = Map.put(wire_payload, "message", message)
        %{:event => "clipboard_copied", :payload => wire_payload}
      {:ping} ->
        wire_payload = %{}
        %{:event => "ping", :payload => wire_payload}
      {:todo_selected, todo_id, from_hook} ->
        wire_payload = %{}
        wire_payload = wire_payload |> Map.put("todo_id", todo_id) |> Map.put("from_hook", from_hook)
        %{:event => "todo_selected", :payload => wire_payload}
    end)
  end
  def decode(event_name, payload) do
    if (event_name == "clipboard_copied") do
      message_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
        Map.get(payload, "message")
      else
        nil
      end
      message = if (Kernel.is_binary(message_raw)), do: message_raw, else: nil
      if (not Kernel.is_nil(message)), do: {:clipboard_copied, message}, else: nil
    else
      if (event_name == "ping") do
        {:ping}
      else
        if (event_name == "todo_selected") do
          todo_id_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
            Map.get(payload, "todo_id")
          else
            nil
          end
          todo_id = if (Kernel.is_integer(todo_id_raw)), do: todo_id_raw, else: nil
          from_hook_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
            Map.get(payload, "from_hook")
          else
            nil
          end
          from_hook = if (Kernel.is_boolean(from_hook_raw)), do: from_hook_raw, else: nil
          if (not Kernel.is_nil(todo_id) and not Kernel.is_nil(from_hook)), do: {:todo_selected, todo_id, from_hook}, else: nil
        else
          nil
        end
      end
    end
  end
end
