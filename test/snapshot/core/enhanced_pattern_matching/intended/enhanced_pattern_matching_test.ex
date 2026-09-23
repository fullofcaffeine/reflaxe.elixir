defmodule EnhancedPatternMatchingTest do
  def match_status(status) do
    (case status do
      {:idle} -> "Currently idle"
      {:working, task} -> "Working on: #{task}"
      {:completed, result, duration} -> "Completed \"#{result}\" in #{Reflaxe.Elixir.HaxeFloat.to_string(duration)}ms"
      {:failed, error, retries} -> "Failed with \"#{error}\" after #{Reflaxe.Elixir.HaxeFloat.to_string(retries)} retries"
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
          {:success, value} -> "Double success: #{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
          {:error, inner_error, inner_context} -> "Outer success, inner error: #{inner_error} (context: #{inner_context})"
        end)
      {:error, outer_error, outer_context} -> "Outer error: #{outer_error} (context: #{outer_context})"
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
        cond do
          duration < 1000 -> "Fast completion: " <> result
          true -> if (duration >= 1000 and duration < 5000), do: "Normal completion: " <> result, else: "Slow completion: " <> result
        end
      {:failed, error, retries} ->
        cond do
          retries < 3 -> "Recoverable failure: " <> error
          true -> "Permanent failure: " <> error
        end
    end)
  end
  def match_with_range_guards(value, category) do
    (case category do
      "score" ->
        n = value
        if (n >= 90) do
          "Excellent score"
        else
          n = value
          if (n >= 70 and n < 90) do
            "Good score"
          else
            n = value
            if (n >= 50 and n < 70) do
              "Average score"
            else
              n = value
              if (n < 50) do
                "Poor score"
              else
                cat = category
                n = value
                "Unknown category \"#{cat}\" with value #{Reflaxe.Elixir.HaxeFloat.to_string(n)}"
              end
            end
          end
        end
      "temperature" ->
        n = value
        if (n >= 30) do
          "Hot"
        else
          n = value
          if (n >= 20 and n < 30) do
            "Warm"
          else
            n = value
            if (n >= 10 and n < 20) do
              "Cool"
            else
              n = value
              if (n < 10) do
                "Cold"
              else
                cat = category
                n = value
                "Unknown category \"#{cat}\" with value #{Reflaxe.Elixir.HaxeFloat.to_string(n)}"
              end
            end
          end
        end
      _ ->
        cat = category
        n = value
        "Unknown category \"#{cat}\" with value #{Reflaxe.Elixir.HaxeFloat.to_string(n)}"
    end)
  end
  def chain_result_operations(input) do
    step1 = validate_input(input)
    (case (case step1 do
      {:success, validated} ->
        process_data(validated)
      {:error, error, context} ->
        context = context || ""
        _result = {:error, error, context}
    end) do
      {:success, processed} ->
        format_output(processed)
      {:error, error, context} ->
        context = context || ""
        _result = {:error, error, context}
    end)
  end
  def match_array_patterns(arr) do
    (case length(arr) do
      0 -> "empty array"
      1 ->
        array_read_node_0 = Enum.at(arr, 0)
        x = array_read_node_0
        "single element: #{Reflaxe.Elixir.HaxeFloat.to_string(x)}"
      2 ->
        array_read_node_1 = Enum.at(arr, 0)
        array_read_node_2 = Enum.at(arr, 1)
        x = array_read_node_1
        y = array_read_node_2
        "pair: [#{Reflaxe.Elixir.HaxeFloat.to_string(x)}, #{Reflaxe.Elixir.HaxeFloat.to_string(y)}]"
      3 ->
        array_read_node_3 = Enum.at(arr, 0)
        array_read_node_4 = Enum.at(arr, 1)
        array_read_node_5 = Enum.at(arr, 2)
        x = array_read_node_3
        y = array_read_node_4
        z = array_read_node_5
        "triple: [#{Reflaxe.Elixir.HaxeFloat.to_string(x)}, #{Reflaxe.Elixir.HaxeFloat.to_string(y)}, #{Reflaxe.Elixir.HaxeFloat.to_string(z)}]"
      _ ->
        a = arr
        if (length(a) > 3) do
          "starts with #{Reflaxe.Elixir.HaxeFloat.to_string(Enum.at(a, 0))}, has #{Reflaxe.Elixir.HaxeFloat.to_string((length(a) - 1))} more elements"
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
        if (StringTools.haxe_substr_non_nil_len(s, 0, 7) == "prefix_") do
          "has prefix: \"#{s}\""
        else
          s = input
          if (StringTools.haxe_substr(s, (String.length(s) - 7), nil) == "_suffix") do
            "has suffix: \"#{s}\""
          else
            s = input
            if (StringTools.haxe_index_of(s, "@", 0) > -1) do
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
      false ->
        age = data.age
        name = data.name
        "Inactive user: #{name} (#{Reflaxe.Elixir.HaxeFloat.to_string(age)})"
      true ->
        age = data.age
        name = data.name
        if (age >= 18) do
          "Active adult: #{name} (#{Reflaxe.Elixir.HaxeFloat.to_string(age)})"
        else
          age = data.age
          name = data.name
          if (age < 18) do
            "Active minor: #{name} (#{Reflaxe.Elixir.HaxeFloat.to_string(age)})"
          else
            "unknown pattern"
          end
        end
      _ -> "unknown pattern"
    end)
  end
  def match_validation_state(state) do
    (case state do
      {:valid} -> "Data is valid"
      {:invalid, errors} ->
        cond do
          length(errors) == 1 -> "Single error: " <> Enum.at(errors, 0)
          true ->
            if (length(errors) > 1) do
              "Multiple errors: " <> Reflaxe.Elixir.HaxeFloat.to_string(length(errors)) <> " issues"
            else
              "No specific errors"
            end
        end
      {:pending, validator} -> "Validation pending by: #{validator}"
    end)
  end
  def match_binary_pattern(data) do
    bytes = Bytes.of_string(data, {:utf8})
    (case bytes.length do
      0 -> "empty"
      1 -> "single byte: #{Reflaxe.Elixir.HaxeFloat.to_string(apply(Map.get(bytes, :__reflaxe_class__) || Map.get(bytes, :__struct__), :get, [bytes, 0]))}"
      _ ->
        n = bytes.length
        if (n <= 4) do
          "small data: #{Reflaxe.Elixir.HaxeFloat.to_string(n)} bytes"
        else
          n = bytes.length
          "large data: #{Reflaxe.Elixir.HaxeFloat.to_string(n)} bytes"
        end
    end)
  end
  defp validate_input(input) do
    if (String.length(input) == 0) do
      context = "validation"
      context = context || ""
      _result = {:error, "Empty input", context}
    else
      if (String.length(input) > 1000) do
        context = "validation"
        context = context || ""
        _result = {:error, "Input too long", context}
      else
        value = String.downcase(input)
        _result = {:success, value}
      end
    end
  end
  defp process_data(data) do
    if (StringTools.haxe_index_of(data, "error", 0) >= 0) do
      context = "processing"
      context = context || ""
      _result = {:error, "Data contains error keyword", context}
    else
      value = String.upcase(data)
      _result = {:success, value}
    end
  end
  defp format_output(data) do
    if (String.length(data) == 0) do
      context = "formatting"
      context = context || ""
      _result = {:error, "No data to format", context}
    else
      _result = {:success, "Formatted: [" <> data <> "]"}
    end
  end
  defp expect(actual, expected) do
    if (actual != expected) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected \"" <> expected <> "\", got \"" <> actual <> "\""]
    end
  end
  def main() do
    expect(match_array_patterns([]), "empty array")
    expect(match_array_patterns([7]), "single element: 7")
    expect(match_array_patterns([7, 8]), "pair: [7, 8]")
    expect(match_array_patterns([7, 8, 9]), "triple: [7, 8, 9]")
    expect(match_array_patterns([7, 8, 9, 10]), "starts with 7, has 3 more elements")
    expect(match_with_range_guards(85, "score"), "Good score")
    expect(match_with_range_guards(25, "temperature"), "Warm")
    expect(match_with_range_guards(5, "other"), "Unknown category \"other\" with value 5")
    result = {:success, "deep value"}
    value = result
    _nested_success = _ = {:success, value}
    nil
  end
end
