defmodule OptionalEvents do
  def encode(event) do
    (case event do
      {:search, query} ->
        wire_payload = %{}
        wire_payload = Map.put(wire_payload, "query", query)
        %{:event => "search", :payload => wire_payload}
      {:save_profile, payload} ->
        form_payload = %{}
        wire_payload = %{}
        form_payload = form_payload |> Map.put("bio", payload.bio) |> Map.put("name", payload.name)
        wire_payload = Map.put(wire_payload, "profile", form_payload)
        %{:event => "save_profile", :payload => wire_payload}
    end)
  end
  def decode(event_name, payload) do
    if (event_name == "save_profile") do
      event_payload_root = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
        Map.get(payload, "profile")
      else
        nil
      end
      event_payload = if (not Kernel.is_nil(event_payload_root) and Kernel.is_map(event_payload_root)), do: event_payload_root, else: %{}
      bio_raw = Map.get(event_payload, "bio")
      bio = if (Kernel.is_binary(bio_raw)), do: bio_raw, else: nil
      name_raw = Map.get(event_payload, "name")
      name = if (Kernel.is_binary(name_raw)), do: name_raw, else: nil
      if (not Kernel.is_nil(name)), do: {:save_profile, %{:bio => bio, :name => name}}, else: nil
    else
      if (event_name == "search") do
        event_payload = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)), do: payload, else: %{}
        query_raw = Map.get(event_payload, "query")
        query = if (Kernel.is_binary(query_raw)), do: query_raw, else: nil
        {:search, query}
      else
        nil
      end
    end
  end
end
