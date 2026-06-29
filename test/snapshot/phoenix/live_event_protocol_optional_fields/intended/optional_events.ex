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
      event_payload = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
        Map.get(payload, "profile")
      else
        nil
      end
      bio_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
        Map.get(event_payload, "bio")
      else
        nil
      end
      bio = if (Kernel.is_binary(bio_raw)), do: bio_raw, else: nil
      name_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
        Map.get(event_payload, "name")
      else
        nil
      end
      name = if (Kernel.is_binary(name_raw)), do: name_raw, else: nil
      if (not Kernel.is_nil(name)), do: {:save_profile, %{:bio => bio, :name => name}}, else: nil
    else
      if (event_name == "search") do
        query_raw = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
          Map.get(payload, "query")
        else
          nil
        end
        query = if (Kernel.is_binary(query_raw)), do: query_raw, else: nil
        {:search, query}
      else
        nil
      end
    end
  end
end
