defmodule Main do
  def main() do
    v = clash({:s_ok, "x"})
    IO.puts(v)
    v = clash({:s_ok, nil})
    IO.puts(v)
    v = clash({:s_err, "e"})
    IO.puts(v)
    v = clash_guard({:s_ok, "y"})
    IO.puts(v)
    v = clash_guard({:s_ok, nil})
    IO.puts(v)
    v = clash_guard({:s_err, "e"})
    IO.puts(v)
  end
  def clash(r) do
    (case r do
      {:s_ok, value} -> if (Kernel.is_nil(value)), do: "inner nil", else: value
      {:s_err, _e} -> "outer nil"
    end)
  end
  def clash_guard(r) do
    switch_result_1 = (case r do
      {:s_ok, value} ->
        cond do
          not Kernel.is_nil(value) -> "inner " <> value
          true -> "inner nil"
        end
      {:s_err, _} -> "outer nil"
    end)
    switch_result_1
  end
end
