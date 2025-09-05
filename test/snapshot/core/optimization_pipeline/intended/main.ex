defmodule Main do
  defp main() do
    test = {:Option1, "test"}
    case (elem(test, 0)) do
      0 ->
        g = elem(test, 1)
        _value = g
        nil
      1 ->
        g = elem(test, 1)
        _data = g
        Log.trace("Option2", %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "main"})
      2 ->
        Log.trace("Option3", %{:fileName => "Main.hx", :lineNumber => 25, :className => "Main", :methodName => "main"})
    end
    Log.trace("This should remain", %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "main"})
    _unused = "This variable is never used"
    used = "This is used"
    Log.trace(used, %{:fileName => "Main.hx", :lineNumber => 38, :className => "Main", :methodName => "main"})
    temp1 = 42
    temp2 = temp1
    result = temp2 + 1
    Log.trace(result, %{:fileName => "Main.hx", :lineNumber => 44, :className => "Main", :methodName => "main"})
    dead_code_example()
  end
  defp dead_code_example() do
    42
    dead_var = "never executed"
    Log.trace(dead_var, %{:fileName => "Main.hx", :lineNumber => 54, :className => "Main", :methodName => "deadCodeExample"})
    0
  end
end