defmodule Log do
  def format_output(v, infos) do
    str = Std.string(v)
    if (infos == nil), do: str
    pstr = infos.file_name <> ":" <> Kernel.to_string(infos.line_number)
    if (Map.get(infos, :custom_params) != nil) do
      g = 0
      g1 = infos.custom_params
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {str, g1, g, :ok}, fn _, {acc_str, acc_g1, acc_g, acc_state} -> nil end)
    end
    pstr <> ": " <> str
  end
  def trace(_v, _infos) do
    IO.puts(str)
  end
end