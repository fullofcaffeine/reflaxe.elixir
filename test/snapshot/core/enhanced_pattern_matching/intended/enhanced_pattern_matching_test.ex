defmodule EnhancedPatternMatchingTest do
  def match_status(status) do
    case status do
      {:idle} ->
        "Currently idle"
      {:working, task} ->
        "Working on: #{task}"
      {:completed, result, duration} ->
        "Completed \"#{result}\" in #{duration}ms"
      {:failed, error, retries} ->
        "Failed with \"#{error}\" after #{retries} retries"
    end
  end
  def incomplete_match(status) do
    case status do
      {:idle} ->
        "idle"
      {:working, task} ->
        "working: #{task}"
      _ ->
        "unknown"
    end
  end
  def match_nested_result(result) do
    case result do
      {:ok, g} ->
        case g do
          {:success, value} ->
            "Double success: #{inspect(value)}"
          {:error, _error, _context} ->
            "Outer success, inner error: #{innerError} (context: #{innerContext})"
        end
      {:error, error, context} ->
        "Outer error: #{outerError} (context: #{outerContext})"
    end
  end
  def match_with_complex_guards(status, priority, is_urgent) do
    case status do
      {:idle} ->
        "idle"
      {:working, priority} when priority > 5 and is_urgent ->
        "High priority urgent task: #{task}"
      {:working, priority} when priority > 3 and not is_urgent ->
        "High priority normal task: #{task}"
      {:working, priority} when priority <= 3 and is_urgent ->
        "Low priority urgent task: #{task}"
      {:working, priority} ->
        "Normal task: #{task}"
      {:completed, result, duration} when duration < 1000 ->
        "Fast completion: #{result}"
      {:completed, result, duration} when duration >= 1000 and duration < 5000 ->
        "Normal completion: #{result}"
      {:completed, result, duration} ->
        "Slow completion: #{result}"
      {:failed, error, retries} when retries < 3 ->
        "Recoverable failure: #{error}"
      {:failed, error, retries} ->
        "Permanent failure: #{error}"
    end
  end
  def match_with_range_guards(value, category) do
    case category do
      "score" ->
        cond do
          n >= 90 -> "Excellent score"
          n >= 70 and n < 90 -> "Good score"
          n >= 50 and n < 70 -> "Average score"
          n < 50 -> "Poor score"
          true -> "Unknown category \"#{cat}\" with value #{n}"
        end
      "temperature" ->
        cond do
          n >= 30 -> "Hot"
          n >= 20 and n < 30 -> "Warm"
          n >= 10 and n < 20 -> "Cool"
          n < 10 -> "Cold"
          true -> "Unknown category \"#{cat}\" with value #{n}"
        end
      _ ->
        "Unknown category \"#{cat}\" with value #{n}"
    end
  end
  def chain_result_operations(input) do
    step1 = validate_input(input)
    step2 = case step1 do
      {:ok, validated} ->
        process_data(validated)
      {:error, error, context} ->
        context2 = context
        if context == nil do
          context2 = ""
        end
        this1 = result
    end
    step3 = case step2 do
      {:ok, processed} ->
        format_output(processed)
      {:error, error, context} ->
        context2 = context
        if context == nil do
          context2 = ""
        end
        this1 = result
    end
    step3
  end
  def match_array_patterns(arr) do
    case (length(arr)) do
      0 ->
        "empty array"
      1 ->
        "single element: #{x}"
      2 ->
        "pair: [#{x}, #{y}]"
      3 ->
        "triple: [#{x}, #{y}, #{z}]"
      _ ->
        a = arr
        if length(a) > 3 do
          "starts with #{a[0]}, has #{(length(a) - 1)} more elements"
        else
          "other array pattern"
        end
    end
  end
  def match_string_patterns(input) do
    if input == "" do
      "empty string"
    else
      s = input
      if length(s) == 1 do
        "single character: \"#{s}\""
      else
        s2 = input
        if String.slice(s2, 0, 7) == "prefix_" do
          "has prefix: \"#{s2}\""
        else
          s3 = input
          pos = (length(s3) - 7)
          pos
          len = nil
          len
          if ((if len == nil do
  String.slice(s3, pos..-1)
else
  String.slice(s3, pos, len)
end) == "_suffix") do
            "has suffix: \"#{s3}\""
          else
            s4 = input
            if ((case :binary.match(s4, "@") do
                {pos, _} -> pos
                nil -> -1
            end) > -1) do
              "contains @: \"#{s4}\""
            else
              s5 = input
              if length(s5) > 100 do
                "very long string"
              else
                s6 = input
                "regular string: \"#{s6}\""
              end
            end
          end
        end
      end
    end
  end
  def match_object_patterns(data) do
    case (data.active) do
      :false ->
        "Inactive user: #{name} (#{age})"
      :true ->
        cond do
          age >= 18 -> "Active adult: #{name} (#{age})"
          age < 18 -> "Active minor: #{name} (#{age})"
          true -> "unknown pattern"
        end
      _ ->
        "unknown pattern"
    end
  end
  def match_validation_state(state) do
    case state do
      {:valid} ->
        "Data is valid"
      {:invalid, errors} when length(errors) == 1 ->
        "Single error: #{errors[0]}"
      {:invalid, errors} when length(errors) > 1 ->
        "Multiple errors: #{length(errors)} issues"
      {:invalid, errors} ->
        "No specific errors"
      {:pending, validator} ->
        "Validation pending by: #{validator}"
    end
  end
  def match_binary_pattern(data) do
    bytes = Bytes.of_string(data)
    case (length(bytes)) do
      0 ->
        "empty"
      1 ->
        "single byte: #{bytes.get(0)}"
      _ ->
        cond do
          n <= 4 -> "small data: #{n} bytes"
          true -> "large data: #{n2} bytes"
        end
    end
  end
  defp validate_input(input) do
    if length(input) == 0 do
      context = "validation"
      if context == nil do
        context = ""
      end
      result = {:error, "Empty input", context}
      this1 = result
    end
    if length(input) > 1000 do
      context = "validation"
      if context == nil do
        context = ""
      end
      result = {:error, "Input too long", context}
      this1 = result
    end
    value = String.downcase(input)
    result = {:success, value}
    this1 = result
  end
  defp process_data(data) do
    if ((case :binary.match(data, "error") do
                {pos, _} -> pos
                nil -> -1
            end) >= 0) do
      context = "processing"
      if context == nil do
        context = ""
      end
      result = {:error, "Data contains error keyword", context}
      this1 = result
    end
    value = String.upcase(data)
    result = {:success, value}
    this1 = result
  end
  defp format_output(data) do
    if length(data) == 0 do
      context = "formatting"
      if context == nil do
        context = ""
      end
      result = {:error, "No data to format", context}
      this1 = result
    end
    result = {:success, "Formatted: [" <> data <> "]"}
    this1 = result
  end
  def main() do
    Log.trace("Enhanced pattern matching compilation test", %{:file_name => "Main.hx", :line_number => 231, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_status({:working, "compile"}), %{:file_name => "Main.hx", :line_number => 234, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_status({:completed, "success", 1500}), %{:file_name => "Main.hx", :line_number => 235, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(incomplete_match({:failed, "timeout", 2}), %{:file_name => "Main.hx", :line_number => 238, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    result = {:success, "deep value"}
    result
    this1 = result
    value = this1
    value
    result = {:success, value}
    result
    this1 = result
    nested_success = this1
    Log.trace(match_nested_result(nested_success), %{:file_name => "Main.hx", :line_number => 242, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_with_complex_guards({:working, "urgent task"}, 8, true), %{:file_name => "Main.hx", :line_number => 245, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_with_range_guards(85, "score"), %{:file_name => "Main.hx", :line_number => 248, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_with_range_guards(25, "temperature"), %{:file_name => "Main.hx", :line_number => 249, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(chain_result_operations("valid input"), %{:file_name => "Main.hx", :line_number => 252, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(chain_result_operations(""), %{:file_name => "Main.hx", :line_number => 253, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_array_patterns([1, 2, 3, 4, 5]), %{:file_name => "Main.hx", :line_number => 256, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_array_patterns([]), %{:file_name => "Main.hx", :line_number => 257, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_string_patterns("prefix_test"), %{:file_name => "Main.hx", :line_number => 260, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_string_patterns("test@example.com"), %{:file_name => "Main.hx", :line_number => 261, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_object_patterns(%{:name => "Alice", :age => 25, :active => true}), %{:file_name => "Main.hx", :line_number => 264, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_object_patterns(%{:name => "Bob", :age => 16, :active => true}), %{:file_name => "Main.hx", :line_number => 265, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_validation_state({:invalid, ["Required field missing", "Invalid format"]}), %{:file_name => "Main.hx", :line_number => 268, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_validation_state({:pending, "security_validator"}), %{:file_name => "Main.hx", :line_number => 269, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_binary_pattern("test"), %{:file_name => "Main.hx", :line_number => 272, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_binary_pattern(""), %{:file_name => "Main.hx", :line_number => 273, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
  end
end