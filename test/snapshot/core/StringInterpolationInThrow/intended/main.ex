defmodule Main do
  defp test_simple_interpolation() do
    error_code = 404
    try do
      throw("Error code: " <> Kernel.to_string(error_code))
    rescue
      e ->
        nil
    end
  end
  defp test_complex_conditional() do
    changeset = %{:errors => ["name is required", "email is invalid"]}
    try do
      errors = get_errors_map(changeset)
      throw("Changeset has errors: " <> (if (not Kernel.is_nil(errors)), do: errors.to_string.(), else: "null"))
    rescue
      e ->
        nil
    end
  end
  defp test_nested_function_calls() do
    data = %{:id => 123, :name => "Test"}
    try do
      throw("Failed to process: " <> format_data(process_data(data)))
    rescue
      e ->
        nil
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
        nil
    end
  end
  defp test_nil_handling() do
    maybe_value = nil
    try do
      throw("Value is: " <> (if (Kernel.is_nil(maybe_value)), do: "nil", else: maybe_value))
    rescue
      e ->
        nil
    end
  end
  defp test_in_raise() do
    module = "UserController"
    func = "show"
    try do
      throw(CustomError.new("Error in " <> module <> "." <> func))
    rescue
      e ->
        nil
    end
  end
  defp get_errors_map(changeset) do
    Map.get(changeset, :errors)
  end
end
