defmodule Main do
  def main() do
    test = {:option1, "test"}
    case (test) do
      {:option1, value} ->
        g = elem(test, 1)
        _value = g
        nil
      {:option2, data} ->
        g = elem(test, 1)
        _data = g
        Log.trace("Option2", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "main"})
      {:option3} ->
        Log.trace("Option3", %{:file_name => "Main.hx", :line_number => 25, :class_name => "Main", :method_name => "main"})
    end
    Log.trace("This should remain", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "main"})
    _unused = "This variable is never used"
    used = "This is used"
    Log.trace(used, %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "main"})
    temp1 = 42
    temp2 = temp1
    result = temp2 + 1
    Log.trace(result, %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "main"})
    dead_code_example()
  end
  defp dead_code_example() do
    42
    dead_var = "never executed"
    Log.trace(dead_var, %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "deadCodeExample"})
    0
  end
end