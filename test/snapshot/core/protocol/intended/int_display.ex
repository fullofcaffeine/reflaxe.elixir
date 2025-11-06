defmodule IntDisplay do
  def display(value) do
    inspect(value)
  end
  def format(value, options) do
    if (Map.get(options, :hex)) do
      "0x#{(fn -> StringTools.hex(value) end).()}"
    end
    _ = inspect(value)
    _
  end
end
