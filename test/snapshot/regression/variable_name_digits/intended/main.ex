defmodule Main do
  def main() do
    pos1 = 10
    pos2 = 20
    array1 = [1, 2, 3]
    item123 = "test"
    value99 = 99
    Log.trace(pos1, %{:fileName => "Main.hx", :lineNumber => 11, :className => "Main", :methodName => "main"})
    Log.trace(pos2, %{:fileName => "Main.hx", :lineNumber => 12, :className => "Main", :methodName => "main"})
    Log.trace(array1, %{:fileName => "Main.hx", :lineNumber => 13, :className => "Main", :methodName => "main"})
    Log.trace(item123, %{:fileName => "Main.hx", :lineNumber => 14, :className => "Main", :methodName => "main"})
    Log.trace(value99, %{:fileName => "Main.hx", :lineNumber => 15, :className => "Main", :methodName => "main"})
    test_params(pos1, pos2)
    user_id1 = "user1"
    user_id2 = "user2"
    html_element5 = "div"
    Log.trace(user_id1, %{:fileName => "Main.hx", :lineNumber => 25, :className => "Main", :methodName => "main"})
    Log.trace(user_id2, %{:fileName => "Main.hx", :lineNumber => 26, :className => "Main", :methodName => "main"})
    Log.trace(html_element5, %{:fileName => "Main.hx", :lineNumber => 27, :className => "Main", :methodName => "main"})
  end
  defp test_params(pos1, pos2) do
    sum = pos1 + pos2
    Log.trace("pos1: " <> pos1 <> ", pos2: " <> pos2 <> ", sum: " <> sum, %{:fileName => "Main.hx", :lineNumber => 33, :className => "Main", :methodName => "testParams"})
  end
end