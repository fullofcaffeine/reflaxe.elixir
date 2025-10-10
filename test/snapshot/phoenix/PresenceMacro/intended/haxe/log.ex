defmodule Log do
  def format_output(v, infos) do
    str = inspect(v)
    if Kernel.is_nil(infos), do: str
    str
  end
  def trace(v, infos) do
    if infos != nil do
      label = "#{infos.fileName}:#{infos.lineNumber}"
      if infos.className != nil do
        label = "#{infos.className}.#{infos.methodName} - #{label}"
      end
      IO.inspect(v, label: label)
    else
      IO.inspect(v)
    end
  end
end