defmodule TestClass do
  def do_something(struct) do
    Log.trace("TestClass doing something with: #{struct.name}", %{:file_name => "SourceMapValidationTest.hx", :line_number => 73, :class_name => "TestClass", :method_name => "doSomething"})
  end
end