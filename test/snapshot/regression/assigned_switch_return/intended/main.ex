defmodule Main do
  defp decide(operation, exists) do
    (case operation do
      {:put, id} ->
        cond do
          id != "ok" -> "rejected"
          true ->
            value = "payload"
            "saved:" <> value
        end
      {:remove} ->
        if (not exists) do
          "missing"
        else
          value = "deleted"
          "saved:#{value}"
        end
    end)
  end
  def main() do
    if (decide({:put, "bad"}, true) != "rejected") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Switch return did not exit the function."]
    end
    if (decide({:remove}, false) != "missing") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Missing-document return did not exit the function."]
    end
    if (decide({:put, "ok"}, true) != "saved:payload") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Valid write changed."]
    end
    if (decide({:remove}, true) != "saved:deleted") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Valid delete changed."]
    end
    if (nested({:put, "bad"}, true) != "outer") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Outer switch exit changed."]
    end
    if (nested({:put, "ok"}, false) != "inner") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested switch exit changed."]
    end
    if (nested({:put, "ok"}, true) != "saved:inside") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested normal continuation changed."]
    end
    if (closure_value(true) != "saved:closure") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Closure return escaped its function."]
    end
    if (closure_value(false) != "saved:other") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Normal alternate branch changed."]
    end
  end
  defp nested(operation, exists) do
    (case operation do
      {:put, id} ->
        if (id != "ok") do
          "outer"
        else
          (case operation do
            {:put, _} ->
              if (not exists) do
                "inner"
              else
                inner = "inside"
                value = inner
                "saved:#{value}"
              end
            {:remove} ->
              inner = "unused"
              value = inner
              "saved:#{value}"
          end)
        end
      {:remove} ->
        value = "removed"
        "saved:#{value}"
    end)
  end
  defp closure_value(selected) do
    value = if (selected) do
      callback = fn -> "closure" end
      callback.()
    else
      "other"
    end
    "saved:#{value}"
  end
end
