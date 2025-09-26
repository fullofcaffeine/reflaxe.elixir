defmodule Log do
  def format_output(v, infos) do
    str = Std.string(v)
    if (infos == nil), do: str
    str
  end
  def trace(v, infos) do
    if (infos != nil) do
      label = "#{infos.file_name}:#{infos.line_number}"
      if (infos.class_name != nil) do
        label = "#{infos.class_name}.#{infos.method_name} - #{label}"
      end
      IO.inspect(v, label: label)
    else
      IO.inspect(v)
    end
  end
end