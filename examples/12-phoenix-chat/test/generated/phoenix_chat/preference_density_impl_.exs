defmodule PhoenixChat.PreferenceDensity_Impl_ do
  def from_wire(value) do
    if (Kernel.is_nil(value)) do
      nil
    else
      (case value do
        "calm" -> "calm"
        "dense" -> "dense"
        "focused" -> "focused"
        _ -> nil
      end)
    end
  end
  def label(this1) do
    (case this1 do
      "calm" -> "Calm"
      "dense" -> "Dense"
      "focused" -> "Focused"
      _ -> "Unknown"
    end)
  end
end
