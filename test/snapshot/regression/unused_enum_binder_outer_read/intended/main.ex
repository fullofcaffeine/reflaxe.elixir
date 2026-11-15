defmodule Main do
  def main() do
    v = outer_argument({:s_ok, "x"}, "P")
    IO.puts(v)
    v = outer_argument({:s_err, "x"}, "P")
    IO.puts(v)
    v = outer_nil_local({:s_ok, "x"})
    IO.puts(v)
    v = outer_set_local({:s_ok, nil})
    IO.puts(v)
    v = reply_argument({:ok, 1}, 50)
    IO.puts(v)
    v = reply_reason({:error, "bad"}, "why")
    IO.puts(v)
    v = inner_switch({:s_ok, "x"}, {:s_ok, "in"}, "P")
    IO.puts(v)
    v = inner_switch({:s_ok, "x"}, {:s_err, "in"}, "P")
    IO.puts(v)
    v = nested_pattern({:wrap, {:s_ok, "x"}})
    IO.puts(v)
    v = nested_pattern({:wrap, {:s_err, "x"}})
    IO.puts(v)
    v = nested_pattern({:both, "a", "b"})
    IO.puts(v)
    v = second_payload({:both, "a", "b"}, "P")
    IO.puts(v)
    v = second_payload({:wrap, {:s_ok, "x"}}, "P")
    IO.puts(v)
  end
  def outer_argument(r, value) do
    (case r do
      {:s_ok, _a} -> "ok #{value}"
      {:s_err, _e} -> "err #{value}"
    end)
  end
  def outer_nil_local(r) do
    switch_result_1 = (case r do
      {:s_ok, _a} -> "outer nil"
      {:s_err, _} -> "e"
    end)
    switch_result_1
  end
  def outer_set_local(r) do
    switch_result_1 = (case r do
      {:s_ok, _a} -> "outer set"
      {:s_err, _} -> "e"
    end)
    switch_result_1
  end
  def reply_argument(r, value) do
    (case r do
      {:ok, _a} -> _ = value + 1
      {:error, _} -> -value
    end)
  end
  def reply_reason(r, reason) do
    (case r do
      {:ok, _} -> reason
      {:error, _x} -> "err/#{reason}"
    end)
  end
  def inner_switch(r, inner, value) do
    (case r do
      {:s_ok, _a} ->
        value <> "|" <> (case inner do
          {:s_ok, payload_value} -> payload_value
          {:s_err, _} -> "e"
        end)
      {:s_err, _} -> "err"
    end)
  end
  def nested_pattern(o) do
    value = "d"
    value = (case o do
      {:wrap, payload_value} ->
        value = (case payload_value do
          {:s_ok, _} ->
            value = "#{value}w"
            value
          {:s_err, _} ->
            value = "#{value}e"
            value
        end)
        value
      {:both, _, b} ->
        value = b
        value
    end)
    value
  end
  def second_payload(o, value) do
    (case o do
      {:wrap, _} -> value
      {:both, _a, b} -> "#{value}#{b}"
    end)
  end
end
