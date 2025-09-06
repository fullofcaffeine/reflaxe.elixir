defmodule Main do
  defp main() do
    test = PropertySetterTest.new()
    test.set_value(42)
    test.set_name("Test")
    if (test.value == 42 && test.name == "Test") do
      Log.trace("Property setters work correctly", %{:fileName => "Main.hx", :lineNumber => 42, :className => "Main", :methodName => "main"})
    end
    test.set_value(100)
    test.set_name("Updated")
    if (test.value == 100 && test.name == "Updated") do
      Log.trace("Chained property setters work", %{:fileName => "Main.hx", :lineNumber => 50, :className => "Main", :methodName => "main"})
    end
  end
end