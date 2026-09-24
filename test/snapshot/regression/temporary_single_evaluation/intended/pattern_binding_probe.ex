defmodule PatternBindingProbe do
  defp classify() do
    header_0 = 255
    header_1 = 254
    header_2 = 4
    header_3 = 0
    switch_result_1 = (case 9 do
      3 ->
        g = header_0
        g_value = header_1
        g2 = header_2
        cond do
          g == 255 ->
            other = g_value
            rest = g2
            cond do
              other != 254 -> "invalid:" <> Reflaxe.Elixir.HaxeFloat.to_string(other) <> ":" <> Reflaxe.Elixir.HaxeFloat.to_string(rest)
              true -> "other"
            end
          true -> "other"
        end
      4 ->
        g = header_0
        g_value = header_1
        g2 = header_2
        g3 = header_3
        cond do
          g == 255 ->
            cond do
              g_value == 254 ->
                length = g2
                version = g3
                if (version == 0 and true) do
                  "packet:" <> Reflaxe.Elixir.HaxeFloat.to_string(length)
                else
                  length = g2
                  version = g3
                  cond do
                    version > 0 -> "future:" <> Reflaxe.Elixir.HaxeFloat.to_string(version) <> ":" <> Reflaxe.Elixir.HaxeFloat.to_string(length)
                    true -> "other"
                  end
                end
              true -> "other"
            end
          true -> "other"
        end
      _ -> "other"
    end)
    switch_result_1
  end
  def main() do
    if (classify() != "other") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Exact-length array patterns changed"]
    end
  end
end
