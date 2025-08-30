defmodule Log do
  def formatOutput(v, infos) do
    fn v, infos -> str = Std.string(v)
if (infos == nil) do
  str
end
pstr = infos.fileName + ":" + infos.lineNumber
if (infos.customParams != nil) do
  g = 0
  g_1 = infos.customParams
  (fn ->
    loop_5 = fn loop_5 ->
      if (g < g1.length) do
        v = g1[g]
      g + 1
      str = str + ", " + Std.string(v)
        loop_5.(loop_5)
      else
        :ok
      end
    end
    loop_5.(loop_5)
  end).()
end
pstr + ": " + str end
  end
  def trace(v, infos) do
    fn v, infos -> str = Log.format_output(v, infos)
Sys.println(str) end
  end
end