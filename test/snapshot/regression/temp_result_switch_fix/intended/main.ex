defmodule Main do
  defp topic_to_string(_topic) do
    case (elem(_topic, 0)) do
      0 ->
        "topic_a"
      1 ->
        "topic_b"
      2 ->
        "topic_c"
    end
  end
  defp get_value(input) do
    result = case (input) do
  1 ->
    "one"
  2 ->
    "two"
  _ ->
    "other"
end
    result
  end
  def main() do
    Log.trace(topic_to_string({0}), %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "main"})
    Log.trace(get_value(1), %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()