defmodule Log do
  def format_output(v, infos) do
    str = Std.string(v)
    if (infos == nil), do: str
    pstr = infos.fileName <> ":" <> infos.lineNumber
    if (infos.customParams != nil) do
      g = 0
      g1 = infos.customParams
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, str, g, :ok}, fn _, {acc_g1, acc_str, acc_g, acc_state} ->
  if (acc_g < acc_g1.length) do
    v = g1[g]
    acc_g = acc_g + 1
    acc_str = acc_str <> ", " <> Std.string(v)
    {:cont, {acc_g1, acc_str, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_str, acc_g, acc_state}}
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