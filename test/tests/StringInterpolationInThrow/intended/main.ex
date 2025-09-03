defmodule Main do
  defp main() do
    test_simple_interpolation()
    test_complex_conditional()
    test_nested_function_calls()
    test_multiple_interpolations()
    test_nil_handling()
    test_in_raise()
  end
  defp test_simple_interpolation() do
    error_code = 404
    try do
      throw("Error code: " <> error_code)
    rescue
      e ->
        Log.trace("Caught: " <> e, %{:fileName => "Main.hx", :lineNumber => 28, :className => "Main", :methodName => "testSimpleInterpolation"})
    end
  end
  defp test_complex_conditional() do
    changeset = %{:errors => ["name is required", "email is invalid"]}
    try do
      errors = get_errors_map(changeset)
      throw("Changeset has errors: " <> (if (errors != nil), do: errors.toString(), else: "null"))
    rescue
      e ->
        Log.trace("Caught: " <> e, %{:fileName => "Main.hx", :lineNumber => 39, :className => "Main", :methodName => "testComplexConditional"})
    end
  end
  defp test_nested_function_calls() do
    data = %{:id => 123, :name => "Test"}
    try do
      throw("Failed to process: " <> format_data(process_data(data)))
    rescue
      e ->
        Log.trace("Caught: " <> e, %{:fileName => "Main.hx", :lineNumber => 49, :className => "Main", :methodName => "testNestedFunctionCalls"})
    end
  end
  defp test_multiple_interpolations() do
    user = "Alice"
    action = "delete"
    resource = "post"
    try do
      throw("User " <> user <> " cannot " <> action <> " resource " <> resource)
    rescue
      e ->
        Log.trace("Caught: " <> e, %{:fileName => "Main.hx", :lineNumber => 61, :className => "Main", :methodName => "testMultipleInterpolations"})
    end
  end
  defp test_nil_handling() do
    maybe_value = nil
    try do
      throw("Value is: " <> (if (maybe_value == nil), do: "nil", else: maybe_value))
    rescue
      e ->
        Log.trace("Caught: " <> e, %{:fileName => "Main.hx", :lineNumber => 71, :className => "Main", :methodName => "testNilHandling"})
    end
  end
  defp test_in_raise() do
    module = "UserController"
    func = "show"
    try do
      throw(CustomError.new("Error in " <> module <> "." <> func))
    rescue
      e ->
        Log.trace("Caught custom error: " <> e.message, %{:fileName => "Main.hx", :lineNumber => 83, :className => "Main", :methodName => "testInRaise"})
    end
  end
  defp get_errors_map(changeset) do
    changeset.errors
  end
  defp process_data(data) do
    %{:processed => true, :original => data}
  end
  defp format_data(data) do
    Std.string(data)
  end
end