defmodule Main do
  def main() do
    _ = Log.trace("Loop A: #{Kernel.to_string(0)}", nil)
    _ = Log.trace("Loop A: #{Kernel.to_string(1)}", nil)
    _ = Log.trace("Loop A: #{Kernel.to_string(2)}", nil)
    _ = some_other_function()
    _ = Log.trace("Loop B: #{Kernel.to_string(0)}", nil)
    _ = Log.trace("Loop B: #{Kernel.to_string(1)}", nil)
    _ = Log.trace("Second: #{Kernel.to_string(0)}", nil)
    _ = Log.trace("Second: #{Kernel.to_string(1)}", nil)
    _g = 0
    _ = Enum.each(0..99//1, fn _ -> nil end)
    nil
  end
  defp some_other_function() do
    nil
  end
end
