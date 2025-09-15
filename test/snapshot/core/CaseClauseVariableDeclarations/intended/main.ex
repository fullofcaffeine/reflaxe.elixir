defmodule Main do
  defp process_result(result) do
    case result do
      {:ok, value} ->
        value

      {:error, error} ->
        message = "Error occurred: #{error}"
        details = "Details: #{message}"
        Log.trace(message, %{:file_name => "Main.hx", :line_number => 22, :class_name => "Main", :method_name => "processResult"})
        Log.trace(details, %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "processResult"})
        details
    end
  end

  defp process_nested_case(result) do
    case result do
      {:ok, value} ->
        if value > 0 do
          positive = "Positive: #{value}"
          positive
        else
          negative = "Negative or zero: #{value}"
          negative
        end

      {:error, error} ->
        error_msg = "Failed: #{error}"
        error_msg
    end
  end

  defp test_function_body() do
    fn = fn x ->
      doubled = x * 2
      tripled = x * 3
      Log.trace("Doubled: #{doubled}, Tripled: #{tripled}", %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "testFunctionBody"})
      doubled + tripled
    end

    fn.(5)
  end

  defp test_try_catch() do
    try do
      risky = perform_risky_operation()
      processed = "Processed: #{risky}"
      processed
    rescue
      e ->
        error_message = "Caught error: #{e}"
        timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
        "#{error_message} #{timestamp}"
    end
  end

  defp perform_risky_operation() do
    if Math.random() > 0.5 do
      throw("Random failure")
    end

    "Success"
  end

  def main() do
    Log.trace(process_result({:ok, "success"}), %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "main"})
    Log.trace(process_result({:error, "failure"}), %{:file_name => "Main.hx", :line_number => 86, :class_name => "Main", :method_name => "main"})
    Log.trace(process_nested_case({:ok, 10}), %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "main"})
    Log.trace(process_nested_case({:ok, -5}), %{:file_name => "Main.hx", :line_number => 89, :class_name => "Main", :method_name => "main"})
    Log.trace(process_nested_case({:error, "invalid"}), %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "main"})
    test_function_body()
    Log.trace(test_try_catch(), %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "main"})
  end
end