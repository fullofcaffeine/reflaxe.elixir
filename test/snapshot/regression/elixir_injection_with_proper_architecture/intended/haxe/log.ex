defmodule Log do
  def format_output(v, infos) do
    str = Std.string(v)
    if (infos == nil), do: str
    pstr = infos.fileName + ":" + infos.lineNumber
    if (infos.customParams != nil) do
      g = 0
      g1 = infos.customParams
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  v = g1[g]
  g + 1
  str = str + ", " + Std.string(v)
  {:cont, acc}
else
  {:halt, acc}
end end)
    end
    pstr + ": " + str
  end
  def trace(v, infos) do
    str = Log.format_output(v, infos)
    Sys.println(str)
  end
end