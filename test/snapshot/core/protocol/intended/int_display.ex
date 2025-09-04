defmodule IntDisplay do
  def display(value) do
    Std.string(value)
  end
  def format(value, options) do
    if (options.hex) do
      "0x" <> StringTools.hex(value)
    end
    Std.string(value)
  end
end