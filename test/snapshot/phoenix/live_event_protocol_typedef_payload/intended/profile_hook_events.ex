defmodule ProfileHookEvents do
  def encode(event) do
    (case event do
      {:clipboard_copied, payload} ->
        wire_payload = %{}
        wire_payload = wire_payload |> Map.put("copied_at", payload.copied_at) |> Map.put("message", payload.message)
        %{:event => "clipboard_copied", :payload => wire_payload}
      {:ping} ->
        wire_payload = %{}
        %{:event => "ping", :payload => wire_payload}
    end)
  end
  def decode(event_name, payload) do
    if (event_name == "clipboard_copied") do
      copied_at_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
        Map.get(payload, "copied_at")
      else
        nil
      end
      copied_at = if (Kernel.is_binary(copied_at_raw)), do: copied_at_raw, else: nil
      message_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
        Map.get(payload, "message")
      else
        nil
      end
      message = if (Kernel.is_binary(message_raw)), do: message_raw, else: nil
      if (not Kernel.is_nil(copied_at) and not Kernel.is_nil(message)), do: {:clipboard_copied, %{:copied_at => copied_at, :message => message}}, else: nil
    else
      if (event_name == "ping"), do: {:ping}, else: nil
    end
  end
end
