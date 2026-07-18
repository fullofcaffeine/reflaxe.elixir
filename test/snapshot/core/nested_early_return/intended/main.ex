defmodule Main do
  def classify(outer, inner) do
    if (outer) do
      if (inner), do: "inner", else: "outer"
    else
      "fallback"
    end
  end
end
