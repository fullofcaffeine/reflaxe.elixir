defmodule ResourceHookEvents do
  def encode(event) do
    (case event do
      {:resource_selected, payload} ->
        wire_payload = %{}
        wire_payload = wire_payload |> Map.put("resource_id", ResourceIdCodec.codec().encode.(payload.resource_id)) |> Map.put("source", payload.source)
        %{:event => "resource_selected", :payload => wire_payload}
      {:ping} ->
        wire_payload = %{}
        %{:event => "ping", :payload => wire_payload}
    end)
  end
  def decode(event_name, payload) do
    if (event_name == "ping") do
      {:ping}
    else
      if (event_name == "resource_selected") do
        resource_id_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
          Map.get(payload, "resource_id")
        else
          nil
        end
        resource_id = if (not Kernel.is_nil(resource_id_raw)), do: ResourceIdCodec.codec().decode.(resource_id_raw), else: nil
        source_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
          Map.get(payload, "source")
        else
          nil
        end
        source = if (Kernel.is_binary(source_raw)), do: source_raw, else: nil
        if (not Kernel.is_nil(resource_id) and not Kernel.is_nil(source)), do: {:resource_selected, %{:resource_id => resource_id, :source => source}}, else: nil
      else
        nil
      end
    end
  end
end
