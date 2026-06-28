defmodule TodoHookEvents do
  def encode(event) do
    (case event do
      {:todo_selected, payload} ->
        wire = %{}
        source = payload.source
        wire = Map.put(wire, "source", source)
        todo_id = payload.todo_id
        todo_id_wire_payload = TodoIdCodec.codec().encode.(todo_id)
        wire = Map.put(wire, "todo_id", todo_id_wire_payload)
        %{:event => "todo_selected", :payload => wire}
      {:ping} ->
        wire = %{}
        %{:event => "ping", :payload => wire}
    end)
  end
  def decode(event_name, payload) do
    if (event_name == "ping") do
      {:ping}
    else
      if (event_name == "todo_selected") do
        source = Phoenix.Channels.WirePayload.get_string(payload, "source")
        raw = Phoenix.Channels.WirePayload.get_payload(payload, "todo_id")
        todo_id = if (not Kernel.is_nil(raw)), do: TodoIdCodec.codec().decode.(raw), else: nil
        if (not Kernel.is_nil(source) and not Kernel.is_nil(todo_id)), do: {:todo_selected, %{:source => source, :todo_id => todo_id}}, else: nil
      else
        nil
      end
    end
  end
end
