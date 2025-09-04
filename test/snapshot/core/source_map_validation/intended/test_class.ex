defmodule TestClass do
  def new(name) do
    %{:name => name}
  end
  def do_something(struct) do
    Log.trace("TestClass doing something with: " <> struct.name, %{:fileName => "SourceMapValidationTest.hx", :lineNumber => 73, :className => "TestClass", :methodName => "doSomething"})
  end
end