defmodule Main do
  def main() do
    pos1 = 10
    pos2 = 20
    array1 = [1, 2, 3]
    item123 = "test"
    value99 = 99
    Log.trace(pos1, %{:file_name => "Main.hx", :line_number => 11, :class_name => "Main", :method_name => "main"})
    Log.trace(pos2, %{:file_name => "Main.hx", :line_number => 12, :class_name => "Main", :method_name => "main"})
    Log.trace(array1, %{:file_name => "Main.hx", :line_number => 13, :class_name => "Main", :method_name => "main"})
    Log.trace(item123, %{:file_name => "Main.hx", :line_number => 14, :class_name => "Main", :method_name => "main"})
    Log.trace(value99, %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "main"})
    test_params(pos1, pos2)
    user_id1 = "user1"
    user_id2 = "user2"
    html_element5 = "div"
    Log.trace(user_id1, %{:file_name => "Main.hx", :line_number => 25, :class_name => "Main", :method_name => "main"})
    Log.trace(user_id2, %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    Log.trace(html_element5, %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
  end
  defp test_params(pos1, pos2) do
    sum = pos1 + pos2
    Log.trace("pos1: #{pos1}, pos2: #{pos2}, sum: #{sum}", %{:file_name => "Main.hx", :line_number => 33, :class_name => "Main", :method_name => "testParams"})
  end
end