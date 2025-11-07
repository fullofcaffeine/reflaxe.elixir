defmodule Main do
  def main() do
    pos1 = 10
    pos2 = 20
    array1 = [1, 2, 3]
    _ = "test"
    _ = 99
    _ = Log.trace(pos1, %{:file_name => "Main.hx", :line_number => 11, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(pos2, %{:file_name => "Main.hx", :line_number => 12, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(array1, %{:file_name => "Main.hx", :line_number => 13, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(item123, %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(value99, %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "main"})
    _ = test_params(pos1, pos2)
    _ = "user1"
    _ = "user2"
    _ = "div"
    _ = Log.trace(user_id1, %{:file_name => "Main.hx", :line_number => 25, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(user_id2, %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(html_element5, %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
  end
  defp test_params(pos1, pos2) do
    sum = pos1 + pos2
    _ = Log.trace("pos1: #{(fn -> pos1 end).()}, pos2: #{(fn -> pos2 end).()}, sum: #{(fn -> sum end).()}", %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testParams"})
  end
end
