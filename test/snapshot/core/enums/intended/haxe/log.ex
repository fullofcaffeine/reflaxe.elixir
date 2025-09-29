defmodule Log do
  def format_output(v, infos) do
    _str = to_string.(v)
    if (infos == nil), do: str
    str
  end
  def trace(v, infos) do
    if (infos != nil) do
      _label = "#{infos.fileName}:#{infos.lineNumber}"
      if (infos.className != nil) do
        label = "#{infos.className}.#{infos.methodName} - #{label}"
      end
      __elixir__.("IO.inspect({0}, label: {1})", v, label)
    else
      __elixir__.("IO.inspect({0})", v)
    end
  end
end