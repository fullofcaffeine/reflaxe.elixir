defmodule ProfileHookEvents do
  def encode(event) do
    (case event do
      {:clipboard_copied, payload} ->
        wire = %{}
        copied_at = payload.copied_at
        wire = Map.put(wire, "copied_at", copied_at)
        message = payload.message
        wire = Map.put(wire, "message", message)
        %{:event => "clipboard_copied", :payload => wire}
      {:ping} ->
        wire = %{}
        %{:event => "ping", :payload => wire}
    end)
  end
  def decode(event_name, payload) do
    if (event_name == "clipboard_copied") do
      copied_at = Phoenix.Channels.WirePayload.get_string(payload, "copied_at")
      message = Phoenix.Channels.WirePayload.get_string(payload, "message")
      if (not Kernel.is_nil(copied_at) and not Kernel.is_nil(message)), do: {:clipboard_copied, %{:copied_at => copied_at, :message => message}}, else: nil
    else
      if (event_name == "ping"), do: {:ping}, else: nil
    end
  end
end
