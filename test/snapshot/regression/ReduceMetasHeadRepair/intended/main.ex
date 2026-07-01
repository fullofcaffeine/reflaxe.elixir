defmodule Main do
  def main() do
    presences = %{"user-a" => %{metas: [%{name: "A", online_at: 1}]}, "user-b" => %{metas: [%{name: "B", online_at: 2}]}}
    names = []
    keys = Map.keys(presences)
    _g = 0
    _ = Enum.reduce(keys, names, fn key, names_acc ->
      entry = Map.get(presences, key, nil)
      if (not Kernel.is_nil(entry) and not Kernel.is_nil(entry.metas) and length(entry.metas) > 0) do
        meta = Enum.at(entry.metas, 0)
        Enum.concat(names_acc, [meta.name <> ":" <> Reflaxe.Elixir.HaxeFloat.to_string(meta.online_at)])
      else
        names_acc
      end
    end)
    nil
  end
end
