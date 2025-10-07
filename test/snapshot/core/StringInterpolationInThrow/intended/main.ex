defmodule Main do
  def main() do
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
      throw("Error code: " <> error_code.to_string())
    rescue
      e ->
        Log.trace("Caught: " <> e, %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "testSimpleInterpolation"})
    end
  end
  defp test_complex_conditional() do
    changeset = %{:errors => ["name is required", "email is invalid"]}
    try do
      errors = get_errors_map(changeset)
      throw("Changeset has errors: " <> if errors != nil, do: errors.toString.(), else: "null")
    rescue
      e ->
        Log.trace("Caught: " <> e, %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "testComplexConditional"})
    end
  end
  defp test_nested_function_calls() do
    data = %{:id => 123, :name => "Test"}
    try do
      throw("Failed to process: " <> format_data(process_data(data)))
    rescue
      e ->
        Log.trace("Caught: " <> e, %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "testNestedFunctionCalls"})
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
        Log.trace("Caught: " <> e, %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "testMultipleInterpolations"})
    end
  end
  defp test_nil_handling() do
    maybe_value = nil
    try do
      throw("Value is: " <> if maybe_value == nil, do: "nil", else: maybe_value)
    rescue
      e ->
        Log.trace("Caught: " <> e, %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "testNilHandling"})
    end
  end
  defp test_in_raise() do
    module = "UserController"
    func = "show"
    try do
      throw(CustomError.new("Error in " <> module <> "." <> func))
    rescue
      e ->
        Log.trace("Caught custom error: " <> e.message, %{:file_name => "Main.hx", :line_number => 83, :class_name => "Main", :method_name => "testInRaise"})
    end
  end
  defp get_errors_map(changeset) do
    Map.get(changeset, :errors)
  end
  defp process_data(data) do
    %{:processed => true, :original => data}
  end
  defp format_data(data) do
    inspect(data)
  end
end