defmodule PhoenixChat.PreferenceStudioContract do
  def decode_payload(params) do
    if (not Kernel.is_map(params)) do
      nil
    else
      keys = Map.keys(params)
      if (length(keys) != 1) do
        nil
      else
        PhoenixChat.PreferenceDensity_Impl_.from_wire(PhoenixHx.Params.get_string(params, "density"))
      end
    end
  end
  def decode_native_button_payload(params) do
    if (not Kernel.is_map(params)) do
      nil
    else
      keys = Map.keys(params)
      if (length(keys) != 2 or PhoenixHx.Params.get_string(params, "value") != "") do
        nil
      else
        PhoenixChat.PreferenceDensity_Impl_.from_wire(PhoenixHx.Params.get_string(params, "density"))
      end
    end
  end
end
