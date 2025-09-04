defmodule Lambda do
  def exists(it, f) do
    x = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {x, :ok}, fn _, {acc_x, acc_state} ->
  if (acc_x.hasNext()) do
    acc_x = acc_x.next()
    if (f.(acc_x)), do: true
    {:cont, {acc_x, acc_state}}
  else
    {:halt, {acc_x, acc_state}}
  end
end)
    false
  end
end