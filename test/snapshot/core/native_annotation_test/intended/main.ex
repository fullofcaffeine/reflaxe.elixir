defmodule Main do
  defp main() do
    result1 = TestModule.original_name()
    result2 = TestModule.normalMethod()
    Log.trace("Mapped method result: " <> result1, %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "main"})
    Log.trace("Normal method result: " <> result2, %{:fileName => "Main.hx", :lineNumber => 19, :className => "Main", :methodName => "main"})
  end
end