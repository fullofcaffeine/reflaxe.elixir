defmodule Log do
  def format_output(v, infos) do
    str = Std.string(v)
    if (infos == nil), do: str
    pstr = infos.fileName <> ":" <> Kernel.to_string(infos.lineNumber)
    if (infos.customParams != nil) do
      g = 0
      g1 = infos.customParams
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, str, :ok}, fn _, {acc_g1, acc_g, acc_str, acc_state} -> nil end)
    end
    pstr <> ": " <> str
  end
  def trace(v, infos) do
    str = Log.format_output(v, infos)
    Sys.println(str)
  end
end