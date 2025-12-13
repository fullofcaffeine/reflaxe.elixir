defmodule EnhancedPatternMatchingTest do
  def match_status(status) do
    (case status do
      {:idle} -> "Currently idle"
      {:working, _task} -> "Working on: #{(fn -> task end).()}"
      {:completed, result, _duration} ->
        duration = result
        "Completed \"#{(fn -> result end).()}\" in #{(fn -> Kernel.to_string(duration) end).()}ms"
      {:failed, error, _retries} ->
        retries = error
        "Failed with \"#{(fn -> error end).()}\" after #{(fn -> Kernel.to_string(retries) end).()} retries"
    end)
  end
  def incomplete_match(status) do
    (case status do
      {:idle} -> "idle"
      {:working, _task} -> "working: #{(fn -> task end).()}"
      _ -> "unknown"
    end)
  end
  def match_nested_result(result) do
    (case result do
      {:success, value} ->
        (case value do
          {:success, value} ->
            inspect = value
            "Double success: #{(fn -> inspect(value) end).()}"
          {:error, reason, _context} ->
            inner_error = reason
            inner_context = reason
            "Outer success, inner error: #{(fn -> inner_error end).()} (context: #{(fn -> inner_context end).()})"
        end)
      {:error, reason, _context} ->
        outer_error = reason
        outer_context = reason
        "Outer error: #{(fn -> outer_error end).()} (context: #{(fn -> outer_context end).()})"
    end)
  end
  def match_with_complex_guards(status, priority, is_urgent) do
    (case status do
      {:idle} -> "idle"
      {:working, task} ->
        if (task > 5 and task) do
          "High priority urgent task: #{(fn -> task end).()}"
        else
          if (task > 3 and not task) do
            "High priority normal task: #{(fn -> task end).()}"
          else
            if (task <= 3 and task) do
              "Low priority urgent task: #{(fn -> task end).()}"
            else
              "Normal task: #{(fn -> task end).()}"
            end
          end
        end
      {:completed, result, duration} ->
        duration = result
        if (duration < 1000) do
          "Fast completion: #{(fn -> result end).()}"
        else
          duration = result
          if (duration >= 1000 and duration < 5000) do
            "Normal completion: #{(fn -> result end).()}"
          else
            _duration = result
            "Slow completion: #{(fn -> result end).()}"
          end
        end
      {:failed, error, retries} ->
        retries = error
        if (retries < 3) do
          "Recoverable failure: #{(fn -> error end).()}"
        else
          _retries = error
          "Permanent failure: #{(fn -> error end).()}"
        end
    end)
  end
  def match_with_range_guards(value, category) do
    (case category do
      "score" when value >= 90 -> "Excellent score"
      "score" when value >= 70 and value < 90 -> "Good score"
      "score" when value >= 50 and value < 70 -> "Average score"
      "score" when value < 50 -> "Poor score"
      "score" ->
        cat = category
        n = value
        "Unknown category \"#{(fn -> cat end).()}\" with value #{(fn -> Kernel.to_string(n) end).()}"
      "temperature" when value >= 30 -> "Hot"
      "temperature" when value >= 20 and value < 30 -> "Warm"
      "temperature" when value >= 10 and value < 20 -> "Cool"
      "temperature" when value < 10 -> "Cold"
      "temperature" ->
        cat = category
        n = value
        "Unknown category \"#{(fn -> cat end).()}\" with value #{(fn -> Kernel.to_string(n) end).()}"
      _ ->
        cat = category
        n = value
        "Unknown category \"#{(fn -> cat end).()}\" with value #{(fn -> Kernel.to_string(n) end).()}"
    end)
  end
  def chain_result_operations(input) do
    _ = validate_input(input)
    (case ((case step1 do
  {:success, validated} ->
    process_data(validated)
  {:error, reason, context} ->
    error = _g
    context = _g1
    if (context == nil) do
      context = ""
    end
    result = {:error, error, context}
    this1 = result
end)) do
      {:success, processed} ->
        format_output(processed)
      {:error, reason, context} ->
        error = reason
        context = reason
        if (Kernel.is_nil(context)) do
          context = ""
        end
        result = {:error, error, context}
    end)
  end
  def match_array_patterns(arr) do
    (case arr do
      [] -> "empty array"
      [head | __tail] ->
        x = head
        "single element: #{(fn -> Kernel.to_string(x) end).()}"
      2 -> "pair: [#{(fn -> Kernel.to_string(x) end).()}, #{(fn -> Kernel.to_string(y) end).()}]"
      3 -> "triple: [#{(fn -> Kernel.to_string(x) end).()}, #{(fn -> Kernel.to_string(y) end).()}, #{(fn -> Kernel.to_string(z) end).()}]"
      _ ->
        a = arr
        if (length(a) > 3) do
          "starts with #{(fn -> Kernel.to_string(a[0]) end).()}, has #{(fn -> Kernel.to_string((length(a) - 1)) end).()} more elements"
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
        s = input
        if (String.slice(s, 0, 7) == "prefix_") do
          "has prefix: \"#{(fn -> s end).()}\""
        else
          s = input
          if ((fn ->
  pos = (length(s) - 7)
  len = nil
  if (Kernel.is_nil(len)) do
    String.slice(s, pos..-1)
  else
    String.slice(s, pos, len)
  end
end).() == "_suffix") do
            "has suffix: \"#{(fn -> s end).()}\""
          else
            s = input
            if (case :binary.match(s, "@") do
                {pos, _} -> pos
                :nomatch -> -1
            end > -1) do
              "contains @: \"#{(fn -> s end).()}\""
            else
              s = input
              if (length(s) > 100) do
                "very long string"
              else
                s = input
                "regular string: \"#{(fn -> s end).()}\""
              end
            end
          end
        end
      end
    end
  end
  def match_object_patterns(data) do
    (case data.active do
      :false -> "Inactive user: #{(fn -> name end).()} (#{(fn -> Kernel.to_string(age) end).()})"
      :true when age >= 18 -> "Active adult: #{(fn -> name end).()} (#{(fn -> Kernel.to_string(age) end).()})"
      :true when age < 18 -> "Active minor: #{(fn -> name end).()} (#{(fn -> Kernel.to_string(age) end).()})"
      :true -> "unknown pattern"
      _ -> "unknown pattern"
    end)
  end
  def match_validation_state(state) do
    (case state do
      {:valid} -> "Data is valid"
      {:invalid, _errors} ->
        cond do
          length(errors) == 1 -> "Single error: " <> errors[0]
          true ->
            errors = _g
            if (length(errors) > 1) do
              "Multiple errors: " <> Kernel.to_string(length(errors)) <> " issues"
            else
              errors = _g
              "No specific errors"
            end
        end
      {:pending, _validator} -> "Validation pending by: #{(fn -> validator end).()}"
    end)
  end
  def match_binary_pattern(data) do
    (case MyApp.Bytes.of_string(data) do
      [] -> "empty"
      [__head | __tail] -> "single byte: #{(fn -> Kernel.to_string(bytes.get(0)) end).()}"
      _ ->
        if (n <= 4) do
          "small data: #{(fn -> Kernel.to_string(n) end).()} bytes"
        else
          "large data: #{(fn -> Kernel.to_string(n) end).()} bytes"
        end
    end)
  end
  defp validate_input(input) do
    if (length(input) == 0) do
      context = "validation"
      if (Kernel.is_nil(context)) do
        context = ""
      end
      result = {:error, "Empty input", context}
    end
    if (length(input) > 1000) do
      context = "validation"
      if (Kernel.is_nil(context)) do
        context = ""
      end
      result = {:error, "Input too long", context}
    end
    value = String.downcase(input)
    result = {:success, value}
  end
  defp format_output(data) do
    if (length(data) == 0) do
      context = "formatting"
      if (Kernel.is_nil(context)) do
        context = ""
      end
      result = {:error, "No data to format", context}
    end
    result = {:success, "Formatted: [" <> data <> "]"}
  end
  def main() do
    nested_success = value = result = {:success, "deep value"}
    result = {:success, value}
    nil
  end
end
