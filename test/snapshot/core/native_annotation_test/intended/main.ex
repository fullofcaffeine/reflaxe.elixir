defmodule Main do
  defp main() do
    result_1 = TestModule.original_name()
    result_2 = TestModule.normal_method()
    Log.trace("Mapped method result: " + result, %{:fileName => "Main.hx", :lineNumber => 18, :className => "Main", :methodName => "main"})
    Log.trace("Normal method result: " + result, %{:fileName => "Main.hx", :lineNumber => 19, :className => "Main", :methodName => "main"})
  end
end