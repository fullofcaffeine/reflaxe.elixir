defmodule IntDisplay do
  def display(value) do
    inspect(value)
  end
  def format(value, options) do
    if (Map.get(options, :hex)) do
      "0x#{StringTools.hex(value, nil)}"
    else
      inspect(value)
    end
  end
end
