defmodule ProfileHookEvents do
  def encode(event) do
    (case event do
      {:clipboard_copied, message} ->
        wire = %{}
        wire = Map.put(wire, "message", message)
        %{:event => "clipboard_copied", :payload => wire}
      {:ping} ->
        wire = %{}
        %{:event => "ping", :payload => wire}
      {:todo_selected, todo_id, from_hook} ->
        wire = %{}
        wire = wire |> Map.put("todo_id", todo_id) |> Map.put("from_hook", from_hook)
        %{:event => "todo_selected", :payload => wire}
    end)
  end
  def decode(event_name, payload) do
    if (event_name == "clipboard_copied") do
      message = Phoenix.Channels.WirePayload.get_string(payload, "message")
      if (not Kernel.is_nil(message)), do: {:clipboard_copied, message}, else: nil
    else
      if (event_name == "ping") do
        {:ping}
      else
        if (event_name == "todo_selected") do
          todo_id = Phoenix.Channels.WirePayload.get_int(payload, "todo_id")
          from_hook = Phoenix.Channels.WirePayload.get_bool(payload, "from_hook")
          if (not Kernel.is_nil(todo_id) and not Kernel.is_nil(from_hook)), do: {:todo_selected, todo_id, from_hook}, else: nil
        else
          nil
        end
      end
    end
  end
end
