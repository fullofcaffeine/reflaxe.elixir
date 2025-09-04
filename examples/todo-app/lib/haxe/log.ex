defmodule Log do
  def format_output(v, infos) do
    str = Std.string(v)
    if (infos == nil), do: str
    pstr = infos.fileName <> ":" <> infos.lineNumber
    if (infos.customParams != nil) do
      g = 0
      g1 = infos.customParams
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, str, :ok}, fn _, {acc_g, acc_str, acc_state} ->
  g = acc_g
  str = acc_str
  if (g < g1.length) do
    v = g1[g]
    g = g + 1
    str = str <> ", " <> Std.string(v)
    {:cont, {g, str, acc_state}}
  else
    {:halt, {g, str, acc_state}}
  end
end)
    end
    pstr <> ": " <> str
  end
  def trace(v, infos) do
    str = format_output(v, infos)
    Sys.println(str)
  end
end