defmodule Lambda do
  def exists(it, f) do
    x = it.iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (x.hasNext()) do
    x = x.next()
    if (f.(x)), do: true
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    false
  end
end