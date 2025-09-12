defmodule Log do
  def format_output(v, infos) do
    str = Std.string(v)
    if (infos == nil), do: str
    pstr = infos.file_name <> ":" <> Kernel.to_string(infos.line_number)
    if (Map.get(infos, :custom_params) != nil) do
      g = 0
      g1 = infos.custom_params
      for v <- g1, do: str = str <> ", " <> Std.string(v)
    end
    pstr <> ": " <> str
  end
  def trace(v, infos) do
    str = format_output(v, infos)
    IO.puts(str)
  end
end