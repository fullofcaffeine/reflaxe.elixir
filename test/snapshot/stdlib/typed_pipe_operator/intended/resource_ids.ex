defmodule ResourceIds do
  def from_param(value) do
    if (Kernel.is_nil(value)) do
      nil
    else
      parsed = (case Integer.parse(value) do
        {num, _} -> num
        :error -> nil
      end)
      if (not Kernel.is_nil(parsed) and parsed > 0) do
        _ = parsed
      else
        nil
      end
    end
  end
  def to_display(id) do
    if (Kernel.is_nil(id)) do
      "missing"
    else
      Reflaxe.Elixir.HaxeFloat.to_string(id)
    end
  end
end
