defmodule Main do
  defp main() do
    x = 42
    y = 3.14
    s = "Hello, AST!"
    b = true
    sum = x + 10
    product = x * 2
    comparison = x > 20
    if b do
      Log.trace("Boolean is true", %{:fileName => "Main.hx", :lineNumber => 16, :className => "Main", :methodName => "main"})
    else
      Log.trace("Boolean is false", %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "main"})
    end
    Log.trace("Sum: " + sum, %{:fileName => "Main.hx", :lineNumber => 22, :className => "Main", :methodName => "main"})
  end
end