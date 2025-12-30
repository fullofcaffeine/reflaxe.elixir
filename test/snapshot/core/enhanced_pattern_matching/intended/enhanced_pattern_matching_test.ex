defmodule EnhancedPatternMatchingTest do
  def match_status(status) do
    (case status do
      {:idle} -> "Currently idle"
      {:working, task} -> "Working on: #{task}"
      {:completed, result, duration} ->
        g_value = duration
        duration = g_value
        "Completed \"#{result}\" in #{Kernel.to_string(duration)}ms"
      {:failed, error, retries} ->
        g_value = retries
        retries = g_value
        "Failed with \"#{error}\" after #{Kernel.to_string(retries)} retries"
    end)
  end
  def incomplete_match(status) do
    (case status do
      {:idle} -> "idle"
      {:working, task} -> "working: #{task}"
      _ -> "unknown"
    end)
  end
  def match_nested_result(result) do
    (case result do
      {:success, value} ->
        (case value do
          {:success, value} -> "Double success: #{inspect(value)}"
          {:error, inner_error, inner_context} ->
            g_value = inner_error
            inner_error = g_value
            inner_context = inner_error
            "Outer success, inner error: #{inner_error} (context: #{inner_context})"
        end)
      {:error, outer_error, outer_context} ->
        g_value = outer_context
        outer_context = g_value
        "Outer error: #{outer_error} (context: #{outer_context})"
    end)
  end
  def match_with_complex_guards(status, priority, is_urgent) do
    (case status do
      {:idle} -> "idle"
      {:working, task} ->
        if (priority > 5 and is_urgent) do
          "High priority urgent task: #{task}"
        else
          if (priority > 3 and not is_urgent) do
            "High priority normal task: #{task}"
          else
            if (priority <= 3 and is_urgent) do
              "Low priority urgent task: #{task}"
            else
              "Normal task: #{task}"
            end
          end
        end
      {:completed, result, duration} ->
        g_value = duration
        duration = g_value
        if (duration < 1000) do
          "Fast completion: #{result}"
        else
          duration = g_value
          if (duration >= 1000 and duration < 5000) do
            "Normal completion: #{result}"
          else
            duration = g_value
            "Slow completion: #{result}"
          end
        end
      {:failed, error, retries} ->
        g_value = retries
        retries = g_value
        if (retries < 3) do
          "Recoverable failure: #{error}"
        else
          retries = g_value
          "Permanent failure: #{error}"
        end
    end)
  end
  def match_with_range_guards(value, category) do
    (case category do
      "score" when value >= 90 -> "Excellent score"
      "score" when value >= 70 and value < 90 -> "Good score"
      "score" when value >= 50 and value < 70 -> "Average score"
      "score" when value < 50 -> "Poor score"
      "score" -> "Unknown category \"#{cat}\" with value #{Kernel.to_string(n)}"
      "temperature" when value >= 30 -> "Hot"
      "temperature" when value >= 20 and value < 30 -> "Warm"
      "temperature" when value >= 10 and value < 20 -> "Cool"
      "temperature" when value < 10 -> "Cold"
      "temperature" -> "Unknown category \"#{cat}\" with value #{Kernel.to_string(n)}"
      cat -> "Unknown category \"#{cat}\" with value #{Kernel.to_string(n)}"
    end)
  end
  def chain_result_operations(input) do
    step1 = validate_input(input)
    (case ((case step1 do
  {:success, validated} -> _ = process_data(validated)
  {:error, error, context} ->
    g_value = context
    context = g_value
    context = if (Kernel.is_nil(context)), do: "", else: context
    _result = {:error, error, context}
end)) do
      {:success, processed} -> _ = format_output(processed)
      {:error, error, context} ->
        g_value = context
        context = g_value
        context = if (Kernel.is_nil(context)), do: "", else: context
        _result = {:error, error, context}
    end)
  end
  def match_array_patterns(arr) do
    (case arr do
      [] -> "empty array"
      [_head | _tail] -> "single element: #{Kernel.to_string(x)}"
      2 ->
        g_value = arr[1]
        x = g
        y = g_value
        "pair: [#{Kernel.to_string(x)}, #{Kernel.to_string(y)}]"
      3 ->
        g_value = arr[1]
        x = g
        y = g_value
        z = g
        "triple: [#{Kernel.to_string(x)}, #{Kernel.to_string(y)}, #{Kernel.to_string(z)}]"
      _ ->
        a = arr
        if (length(a) > 3) do
          "starts with #{Kernel.to_string(a[0])}, has #{Kernel.to_string((length(a) - 1))} more elements"
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
      if (String.length(s) == 1) do
        "single character: \"#{s}\""
      else
        s = input
        if (String.slice(s, 0, 7) == "prefix_") do
          "has prefix: \"#{s}\""
        else
          s = input
          if (String.slice(s, (String.length(s) - 7)..-1//1) == "_suffix") do
            "has suffix: \"#{s}\""
          else
            s = input
            cond_value = ((case :binary.match(s, "@") do
  {pos, _} -> pos
  :nomatch -> -1
end))
            if (cond_value > -1) do
              "contains @: \"#{s}\""
            else
              s = input
              if (String.length(s) > 100) do
                "very long string"
              else
                s = input
                "regular string: \"#{s}\""
              end
            end
          end
        end
      end
    end
  end
  def match_object_patterns(data) do
    (case data.active do
      :false -> "Inactive user: #{name} (#{Kernel.to_string(age)})"
      :true when age >= 18 -> "Active adult: #{name} (#{Kernel.to_string(age)})"
      :true when age < 18 -> "Active minor: #{name} (#{Kernel.to_string(age)})"
      :true -> "unknown pattern"
      _ -> "unknown pattern"
    end)
  end
  def match_validation_state(state) do
    (case state do
      {:valid} -> "Data is valid"
      {:invalid, errors} ->
        if (length(errors) == 1) do
          "Single error: #{errors[0]}"
        else
          if (length(errors) > 1) do
            "Multiple errors: #{Kernel.to_string(length(errors))} issues"
          else
            "No specific errors"
          end
        end
      {:pending, validator} -> "Validation pending by: #{validator}"
    end)
  end
  def match_binary_pattern(data) do
    bytes = (case Bytes.of_string(data, nil) do
      [] -> "empty"
      [_head | _tail] -> "single byte: #{Kernel.to_string(bytes.get(bytes, 0))}"
      _ ->
        if (n <= 4) do
          "small data: #{Kernel.to_string(n)} bytes"
        else
          n = g
          "large data: #{Kernel.to_string(n)} bytes"
        end
    end)
    bytes
  end
  defp validate_input(input) do
    if (String.length(input) == 0) do
      context = "validation"
      context = if (Kernel.is_nil(context)), do: "", else: context
      _result = {:error, "Empty input", context}
    else
      if (String.length(input) > 1000) do
        context = "validation"
        context = if (Kernel.is_nil(context)), do: "", else: context
        _result = {:error, "Input too long", context}
      else
        value = String.downcase(input)
        _result = {:success, value}
      end
    end
  end
  defp process_data(data) do
    cond_value = ((case :binary.match(data, "error") do
  {pos, _} -> pos
  :nomatch -> -1
end))
    if (cond_value >= 0) do
      context = "processing"
      context = if (Kernel.is_nil(context)), do: "", else: context
      _result = {:error, "Data contains error keyword", context}
    else
      value = String.upcase(data)
      _result = {:success, value}
    end
  end
  defp format_output(data) do
    if (String.length(data) == 0) do
      context = "formatting"
      context = if (Kernel.is_nil(context)), do: "", else: context
      _result = {:error, "No data to format", context}
    else
      _result = {:success, "Formatted: [" <> data <> "]"}
    end
  end
  def main() do
    value = nil
    _nested_success = _result = {:success, value}
    nil
  end
end
