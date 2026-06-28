defmodule ResourceHookEvents do
  def encode(event) do
    (case event do
      {:resource_selected, payload} ->
        wire = %{}
        resource_id = payload.resource_id
        resource_id_wire_payload = ResourceIdCodec.codec().encode.(resource_id)
        wire = Map.put(wire, "resource_id", resource_id_wire_payload)
        source = payload.source
        wire = Map.put(wire, "source", source)
        %{:event => "resource_selected", :payload => wire}
      {:ping} ->
        wire = %{}
        %{:event => "ping", :payload => wire}
    end)
  end
  def decode(event_name, payload) do
    if (event_name == "ping") do
      {:ping}
    else
      if (event_name == "resource_selected") do
        raw = Phoenix.Channels.WirePayload.get_payload(payload, "resource_id")
        resource_id = if (not Kernel.is_nil(raw)), do: ResourceIdCodec.codec().decode.(raw), else: nil
        source = Phoenix.Channels.WirePayload.get_string(payload, "source")
        if (not Kernel.is_nil(resource_id) and not Kernel.is_nil(source)), do: {:resource_selected, %{:resource_id => resource_id, :source => source}}, else: nil
      else
        nil
      end
    end
  end
end
