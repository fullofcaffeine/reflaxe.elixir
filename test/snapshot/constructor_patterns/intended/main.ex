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
    _name = "Alice"
    _email = "alice@example.com"
    Log.trace("Schema test: #{user.name}", %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "testSchemaConstructor"})
  end

  defp test_regular_class() do
    formatter1 = TodoFormatter.new("markdown", "TODO")
    _formatter2 = TodoFormatter.new("plain")
    todo = %{:title => "Test Todo", :completed => false}
    Log.trace("Formatted: #{formatter1.format_todo(todo)}", %{:file_name => "Main.hx", :line_number => 94, :class_name => "Main", :method_name => "testRegularClass"})
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
    # Create users using comprehension
    users = for i <- 0..4 do
      %ConstructorTest.User{
        name: "User #{i}",
        email: "user#{i}@example.com"
      }
    end

    Log.trace("Created #{length(users)} users", %{:file_name => "Main.hx", :line_number => 118, :class_name => "Main", :method_name => "testMultipleInstances"})

    # Create formatters
    _formatter_0 = TodoFormatter.new("markdown", "- [ ]")
    _formatter_1 = TodoFormatter.new("org", "TODO")
    _formatter_2 = TodoFormatter.new("plain", "*")

    Log.trace("Created 3 formatters", %{:file_name => "Main.hx", :line_number => 127, :class_name => "Main", :method_name => "testMultipleInstances"})
  end
end