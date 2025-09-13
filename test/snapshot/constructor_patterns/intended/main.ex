defmodule Main do
  def main() do
    test_schema_constructor()
    test_regular_class()
    test_gen_server()
    test_data_structures()
    test_multiple_instances()
  end
  defp test_schema_constructor() do
    user = %ConstructorTest.User{}
    name = "Alice"
    email = "alice@example.com"
    Log.trace("Schema test: " <> user.name, %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "testSchemaConstructor"})
  end
  defp test_regular_class() do
    formatter1 = TodoFormatter.new("markdown", "TODO")
    _formatter2 = TodoFormatter.new("plain")
    todo = %{:title => "Test Todo", :completed => false}
    Log.trace("Formatted: " <> formatter1.format_todo(todo), %{:file_name => "Main.hx", :line_number => 94, :class_name => "Main", :method_name => "testRegularClass"})
  end
  defp test_gen_server() do
    _worker = TodoWorker.new(%{:todos => []})
    Log.trace("Worker started", %{:file_name => "Main.hx", :line_number => 100, :class_name => "Main", :method_name => "testGenServer"})
  end
  defp test_data_structures() do
    DataStructureTest.test_collections()
    Log.trace("Data structures initialized", %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testDataStructures"})
  end
  defp test_multiple_instances() do
    users = []
    user = %ConstructorTest.User{}
    name = "User " <> Kernel.to_string(0)
    email = "user" <> Kernel.to_string(0) <> "@example.com"
    users = users ++ [user]
    user = %ConstructorTest.User{}
    name = "User " <> Kernel.to_string(1)
    email = "user" <> Kernel.to_string(1) <> "@example.com"
    users = users ++ [user]
    user = %ConstructorTest.User{}
    name = "User " <> Kernel.to_string(2)
    email = "user" <> Kernel.to_string(2) <> "@example.com"
    users = users ++ [user]
    user = %ConstructorTest.User{}
    name = "User " <> Kernel.to_string(3)
    email = "user" <> Kernel.to_string(3) <> "@example.com"
    users = users ++ [user]
    user = %ConstructorTest.User{}
    name = "User " <> Kernel.to_string(4)
    email = "user" <> Kernel.to_string(4) <> "@example.com"
    users = users ++ [user]
    Log.trace("Created " <> Kernel.to_string(length(users)) <> " users", %{:file_name => "Main.hx", :line_number => 118, :class_name => "Main", :method_name => "testMultipleInstances"})
    formatters_0 = TodoFormatter.new("markdown", "- [ ]")
    formatters_1 = TodoFormatter.new("org", "TODO")
    formatters_2 = TodoFormatter.new("plain", "*")
    Log.trace("Created " <> Kernel.to_string(3) <> " formatters", %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testMultipleInstances"})
  end
end