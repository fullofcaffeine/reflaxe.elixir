defmodule TodoIdCodec do
  def codec() do
    %{:encode => fn value -> Map.put(%{}, "value", value) end, :decode => fn payload ->
  value = Phoenix.Channels.WirePayload.get_int(payload, "value")
  if (Kernel.is_nil(value)), do: nil, else: value
end}
  end
end
