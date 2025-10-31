defmodule EnhancedPatternMatchingTest do
  def match_status(status) do
    (case status do
      {:idle} -> "Currently idle"
      {:working, _value} ->
        fn_ = _value
        task = _value
        "Working on: #{(fn -> task end).()}"
      {:completed, result, duration} -> "Completed \"#{(fn -> result end).()}\" in #{(fn -> duration end).()}ms"
      {:failed, error, retries} -> "Failed with \"#{(fn -> error end).()}\" after #{(fn -> retries end).()} retries"
    end)
  end
  def incomplete_match(status) do
    (case status do
      {:idle} -> "idle"
      {:working, _value} ->
        fn_ = _value
        task = _value
        "working: #{(fn -> task end).()}"
      _ -> "unknown"
    end)
  end
  def match_nested_result(result) do
    (case result do
      {:success, value} ->
        inner_error = value
        _value = value
        (case value do
          {:success, _value} ->
            inspect = _value
            value = _value
            "Double success: #{(fn -> inspect(value) end).()}"
          {:error, inner_error, inner_context} -> "Outer success, inner error: #{(fn -> inner_error end).()} (context: #{(fn -> inner_context end).()})"
        end)
      {:error, outer_error, outer_context} -> "Outer error: #{(fn -> outer_error end).()} (context: #{(fn -> outer_context end).()})"
    end)
  end
  def match_with_complex_guards(status, priority, is_urgent) do
    (case status do
      {:idle} -> "idle"
      {:working, _value} when priority > 5 and is_urgent ->
        fn_ = _value
        task = _value
        "High priority urgent task: #{(fn -> task end).()}"
      {:working, _value} when priority > 3 and not is_urgent ->
        fn_ = _value
        task = _value
        "High priority normal task: #{(fn -> task end).()}"
      {:working, _value} when priority <= 3 and is_urgent ->
        fn_ = _value
        task = _value
        "Low priority urgent task: #{(fn -> task end).()}"
      {:working, _value} ->
        fn_ = _value
        task = _value
        "Normal task: #{(fn -> task end).()}"
      {:completed, duration, result} when duration < 1000 -> "Fast completion: #{(fn -> result end).()}"
      {:completed, duration, result} when duration >= 1000 and duration < 5000 -> "Normal completion: #{(fn -> result end).()}"
      {:completed, _duration, result} -> "Slow completion: #{(fn -> result end).()}"
      {:failed, retries, error} when retries < 3 -> "Recoverable failure: #{(fn -> error end).()}"
      {:failed, _retries, error} -> "Permanent failure: #{(fn -> error end).()}"
    end)
  end
  def match_with_range_guards(value, category) do
    (case category do
      "score" when value >= 90 -> "Excellent score"
      "score" when value >= 70 and value < 90 -> "Good score"
      "score" when value >= 50 and value < 70 -> "Average score"
      "score" when value < 50 -> "Poor score"
      "score" -> "Unknown category \"#{(fn -> cat end).()}\" with value #{(fn -> n end).()}"
      "temperature" when value >= 30 -> "Hot"
      "temperature" when value >= 20 and value < 30 -> "Warm"
      "temperature" when value >= 10 and value < 20 -> "Cool"
      "temperature" when value < 10 -> "Cold"
      "temperature" -> "Unknown category \"#{(fn -> cat end).()}\" with value #{(fn -> n end).()}"
      _ ->
        cat = category
        n = value
        "Unknown category \"#{(fn -> cat end).()}\" with value #{(fn -> n end).()}"
    end)
  end
  def chain_result_operations(input) do
    _ = validate_input(input)
    parsed_result = ((case step1 do
  {:success, validated} ->
    process_data(validated)
  {:error, context2, this1} ->
    error = _g
    context = _g1
    context2 = context
    if (context2 == nil) do
      context2 = ""
    end
    this1 = result
end))
    (case parsed_result do
      {:success, processed} ->
        format_output(processed)
      {:error, context, this1} ->
        _ = context
        if (Kernel.is_nil(context)) do
          context = ""
        end
    end)
  end
  def match_array_patterns(arr) do
    (case arr do
      [] -> "empty array"
      [_head | _tail] -> "single element: #{(fn -> x end).()}"
      2 -> "pair: [#{(fn -> x end).()}, #{(fn -> y end).()}]"
      3 -> "triple: [#{(fn -> x end).()}, #{(fn -> y end).()}, #{(fn -> z end).()}]"
      _ ->
        a = arr
        if (length(a) > 3) do
          "starts with #{(fn -> a[0] end).()}, has #{(fn -> (length(a) - 1) end).()} more elements"
        else
          "other array pattern"
        end
    end)
  end
  def match_string_patterns(input) do
    if (input == "") do
      "empty string"
    else
      s = input
      if (length(s) == 1) do
        "single character: \"#{(fn -> s end).()}\""
      else
        s2 = input
        if (String.slice(s2, 0, 7) == "prefix_") do
          "has prefix: \"#{(fn -> s2 end).()}\""
        else
          s3 = input
          if ((fn ->
  pos = (length(s3) - 7)
  len = nil
  if (Kernel.is_nil(len)) do
    String.slice(s3, pos..-1)
  else
    String.slice(s3, pos, len)
  end
end).() == "_suffix") do
            "has suffix: \"#{(fn -> s3 end).()}\""
          else
            s4 = input
            if (case :binary.match(s4, "@") do
                {pos, _} -> pos
                :nomatch -> -1
            end > -1) do
              "contains @: \"#{(fn -> s4 end).()}\""
            else
              s5 = input
              if (length(s5) > 100) do
                "very long string"
              else
                s6 = input
                "regular string: \"#{(fn -> s6 end).()}\""
              end
            end
          end
        end
      end
    end
  end
  def match_object_patterns(data) do
    (case data.active do
      :false -> "Inactive user: #{(fn -> name end).()} (#{(fn -> age end).()})"
      :true when age >= 18 -> "Active adult: #{(fn -> name end).()} (#{(fn -> age end).()})"
      :true when age < 18 -> "Active minor: #{(fn -> name end).()} (#{(fn -> age end).()})"
      :true -> "unknown pattern"
      _ -> "unknown pattern"
    end)
  end
  def match_validation_state(state) do
    (case state do
      {:valid} -> "Data is valid"
      {:invalid, _value} when length(errors) == 1 ->
        errors = _value
        fn_ = _value
        "Single error: #{(fn -> errors[0] end).()}"
      {:invalid, _value} when length(errors) > 1 ->
        fn_ = _value
        length = _value
        "Multiple errors: #{(fn -> length(errors) end).()} issues"
      {:invalid, _value} -> "No specific errors"
      {:pending, _value} ->
        fn_ = _value
        validator = _value
        "Validation pending by: #{(fn -> validator end).()}"
    end)
  end
  def match_binary_pattern(data) do
    parsed_result = MyApp.Bytes.of_string(data)
    (case parsed_result do
      [] -> "empty"
      [head | tail] -> "single byte: #{(fn -> bytes.get(0) end).()}"
      _ ->
        if (n <= 4) do
          "small data: #{(fn -> n end).()} bytes"
        else
          "large data: #{(fn -> n2 end).()} bytes"
        end
    end)
  end
  defp validate_input(input) do
    if (length(input) == 0) do
      context = "validation"
      nil
      _ = {:error, "Empty input", context}
    end
    if (length(input) > 1000) do
      context = "validation"
      nil
      _ = {:error, "Input too long", context}
    end
    value = String.downcase(input)
    _ = {:success, value}
  end
  defp format_output(data) do
    if (length(data) == 0) do
      context = "formatting"
      nil
      _ = {:error, "No data to format", context}
    end
    _ = {:success, "Formatted: [" <> data <> "]"}
  end
  def main() do
    Log.trace("Enhanced pattern matching compilation test", %{:file_name => "Main.hx", :line_number => 231, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_status({:working, "compile"}), %{:file_name => "Main.hx", :line_number => 234, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_status({:completed, "success", 1500}), %{:file_name => "Main.hx", :line_number => 235, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(incomplete_match({:failed, "timeout", 2}), %{:file_name => "Main.hx", :line_number => 238, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    nested_success = value = _ = {:success, "deep value"}
    _ = {:success, value}
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
