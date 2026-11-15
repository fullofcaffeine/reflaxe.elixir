defmodule Main do
  def main() do
    v = outer_value({:ok, 2}, 10)
    IO.puts(v)
    v = outer_value({:err, {:stale, 3, 1}}, 10)
    IO.puts(v)
    v = outer_value({:err, {:fresh, 4}}, 10)
    IO.puts(v)
    v = local_value({:ok, 2})
    IO.puts(v)
    v = outer_reason({:error, "bad"}, "why")
    IO.puts(v)
    v = outer_reason({:ok, 5}, "why")
    IO.puts(v)
    VisibleNames.run()
  end
  def outer_value(r, value) do
    (case r do
      {:ok, v} -> v + value
      {:err, e} ->
        (case e do
          {:stale, wanted, _} -> wanted + value
          {:fresh, n} -> n * value
        end)
    end)
  end
  def local_value(r) do
    value = 100
    switch_result_1 = (case r do
      {:ok, v} -> v + value
      {:err, _} -> value
    end)
    switch_result_1
  end
  def outer_reason(r, reason) do
    (case r do
      {:ok, value} ->
        v = value
        "#{reason}#{Reflaxe.Elixir.HaxeFloat.to_string(v)}"
      {:error, v} -> "#{v}/#{reason}"
    end)
  end
end
