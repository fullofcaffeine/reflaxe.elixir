defmodule Main do
  def main() do
    test_result = {:Ok, "success"}
    opt = to_option(test_result)
    unwrapped = unwrap_or(test_result, "default")
    Log.trace(opt, %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    Log.trace(unwrapped, %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
  end
  def to_option(_result) do
    case (elem(_result, 0)) do
      0 ->
        g = elem(_result, 1)
        value = g
        {:Some, value}
      1 ->
        _g = elem(_result, 1)
        {1}
    end
  end
  def unwrap_or(_result, default_value) do
    case (elem(_result, 0)) do
      0 ->
        g = elem(_result, 1)
        value = g
        value
      1 ->
        _g = elem(_result, 1)
        default_value
    end
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()