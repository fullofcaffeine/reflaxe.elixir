defmodule Main do
  def main() do
    result1 = TestModule.original_name()
    result2 = TestModule.normal_method()
    Log.trace("Mapped method result: #{result1}", %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "main"})
    Log.trace("Normal method result: #{result2}", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "main"})
  end
end