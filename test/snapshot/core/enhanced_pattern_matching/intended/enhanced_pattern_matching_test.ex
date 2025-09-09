defmodule EnhancedPatternMatchingTest do
  def match_status(_status) do
    case (elem(_status, 0)) do
      0 ->
        "Currently idle"
      1 ->
        g = elem(_status, 1)
        task = g
        "Working on: " <> task
      2 ->
        g = elem(_status, 1)
        g1 = elem(_status, 2)
        result = g
        duration = g1
        "Completed \"" <> result <> "\" in " <> Kernel.to_string(duration) <> "ms"
      3 ->
        g = elem(_status, 1)
        g1 = elem(_status, 2)
        error = g
        retries = g1
        "Failed with \"" <> error <> "\" after " <> Kernel.to_string(retries) <> " retries"
    end
  end
  def incomplete_match(_status) do
    case (elem(_status, 0)) do
      0 ->
        "idle"
      1 ->
        g = elem(_status, 1)
        task = g
        "working: " <> task
      _ ->
        "unknown"
    end
  end
  def match_nested_result(_result) do
    case (elem(_result, 0)) do
      0 ->
        g = elem(_result, 1)
        case (elem(g, 0)) do
          0 ->
            g = elem(g, 1)
            value = g
            "Double success: " <> Std.string(value)
          1 ->
            g1 = elem(g, 1)
            g = elem(g, 2)
            inner_error = g1
            inner_context = g
            "Outer success, inner error: " <> inner_error <> " (context: " <> inner_context <> ")"
        end
      1 ->
        g = elem(_result, 1)
        g1 = elem(_result, 2)
        outer_error = g
        outer_context = g1
        "Outer error: " <> outer_error <> " (context: " <> outer_context <> ")"
    end
  end
  def match_with_complex_guards(_status, priority, is_urgent) do
    case (elem(_status, 0)) do
      0 ->
        "idle"
      1 ->
        g = elem(_status, 1)
        task = g
        if (priority > 5 && is_urgent) do
          "High priority urgent task: " <> task
        else
          task = g
          if (priority > 3 && not is_urgent) do
            "High priority normal task: " <> task
          else
            task = g
            if (priority <= 3 && is_urgent) do
              "Low priority urgent task: " <> task
            else
              task = g
              "Normal task: " <> task
            end
          end
        end
      2 ->
        g = elem(_status, 1)
        g1 = elem(_status, 2)
        result = g
        duration = g1
        if (duration < 1000) do
          "Fast completion: " <> result
        else
          result = g
          duration = g1
          if (duration >= 1000 && duration < 5000) do
            "Normal completion: " <> result
          else
            result = g
            _duration = g1
            "Slow completion: " <> result
          end
        end
      3 ->
        g = elem(_status, 1)
        g1 = elem(_status, 2)
        error = g
        retries = g1
        if (retries < 3) do
          "Recoverable failure: " <> error
        else
          error = g
          _retries = g1
          "Permanent failure: " <> error
        end
    end
  end
  def match_with_range_guards(_value, category) do
    case (category) do
      "score" ->
        n = _value
        if (n >= 90) do
          "Excellent score"
        else
          n = _value
          if (n >= 70 && n < 90) do
            "Good score"
          else
            n = _value
            if (n >= 50 && n < 70) do
              "Average score"
            else
              n = _value
              if (n < 50) do
                "Poor score"
              else
                cat = category
                n = _value
                "Unknown category \"" <> cat <> "\" with value " <> Kernel.to_string(n)
              end
            end
          end
        end
      "temperature" ->
        n = _value
        if (n >= 30) do
          "Hot"
        else
          n = _value
          if (n >= 20 && n < 30) do
            "Warm"
          else
            n = _value
            if (n >= 10 && n < 20) do
              "Cool"
            else
              n = _value
              if (n < 10) do
                "Cold"
              else
                cat = category
                n = _value
                "Unknown category \"" <> cat <> "\" with value " <> Kernel.to_string(n)
              end
            end
          end
        end
      _ ->
        cat = category
        n = _value
        "Unknown category \"" <> cat <> "\" with value " <> Kernel.to_string(n)
    end
  end
  def chain_result_operations(input) do
    step1 = validate_input(input)
    step2 = case (elem(step1, 0)) do
  0 ->
    g = elem(step1, 1)
    validated = g
    process_data(validated)
  1 ->
    g = elem(step1, 1)
    g1 = elem(step1, 2)
    error = g
    context = g1
    context = context
    if (context == nil) do
      context = ""
    end
    result = {:Error, error, context}
    this1 = nil
    this1 = result
    this1
end
    step3 = case (elem(step2, 0)) do
  0 ->
    g = elem(step2, 1)
    processed = g
    format_output(processed)
  1 ->
    g = elem(step2, 1)
    g1 = elem(step2, 2)
    error = g
    context = g1
    context = context
    if (context == nil) do
      context = ""
    end
    result = {:Error, error, context}
    this1 = nil
    this1 = result
    this1
end
    step3
  end
  def match_array_patterns(arr) do
    case (length(arr)) do
      0 ->
        "empty array"
      1 ->
        g = arr[0]
        x = g
        "single element: " <> Kernel.to_string(x)
      2 ->
        g = arr[0]
        g1 = arr[1]
        x = g
        y = g1
        "pair: [" <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y) <> "]"
      3 ->
        g = arr[0]
        g1 = arr[1]
        g2 = arr[2]
        x = g
        y = g1
        z = g2
        "triple: [" <> Kernel.to_string(x) <> ", " <> Kernel.to_string(y) <> ", " <> Kernel.to_string(z) <> "]"
      _ ->
        a = arr
        if (length(a) > 3) do
          "starts with " <> Kernel.to_string(a[0]) <> ", has " <> Kernel.to_string(((length(a) - 1))) <> " more elements"
        else
          "other array pattern"
        end
    end
  end
  def match_string_patterns(input) do
    if (input == "") do
      "empty string"
    else
      s = input
      if (length(s) == 1) do
        "single character: \"" <> s <> "\""
      else
        s = input
        if (s.substr(0, 7) == "prefix_") do
          "has prefix: \"" <> s <> "\""
        else
          s = input
          if (s.substr((length(s) - 7)) == "_suffix") do
            "has suffix: \"" <> s <> "\""
          else
            s = input
            if (s.index_of("@") > -1) do
              "contains @: \"" <> s <> "\""
            else
              s = input
              if (length(s) > 100) do
                "very long string"
              else
                s = input
                "regular string: \"" <> s <> "\""
              end
            end
          end
        end
      end
    end
  end
  def match_object_patterns(_data) do
    g = _data.name
    g1 = _data.age
    g2 = _data.active
    case (g2) do
      false ->
        age = g1
        name = g
        "Inactive user: " <> name <> " (" <> Kernel.to_string(age) <> ")"
      true ->
        age = g1
        name = g
        if (age >= 18) do
          "Active adult: " <> name <> " (" <> Kernel.to_string(age) <> ")"
        else
          age = g1
          name = g
          if (age < 18) do
            "Active minor: " <> name <> " (" <> Kernel.to_string(age) <> ")"
          else
            "unknown pattern"
          end
        end
      _ ->
        "unknown pattern"
    end
  end
  def match_validation_state(_state) do
    case (elem(_state, 0)) do
      0 ->
        "Data is valid"
      1 ->
        g = elem(_state, 1)
        errors = g
        if (length(errors) == 1) do
          "Single error: " <> errors[0]
        else
          errors = g
          if (length(errors) > 1) do
            "Multiple errors: " <> Kernel.to_string(length(errors)) <> " issues"
          else
            _errors = g
            "No specific errors"
          end
        end
      2 ->
        g = elem(_state, 1)
        validator = g
        "Validation pending by: " <> validator
    end
  end
  def match_binary_pattern(data) do
    bytes = Bytes.of_string(data)
    g = length(bytes)
    case (g) do
      0 ->
        "empty"
      1 ->
        "single byte: " <> Kernel.to_string(:binary.at(bytes, 0))
      _ ->
        n = g
        if (n <= 4) do
          "small data: " <> Kernel.to_string(n) <> " bytes"
        else
          n = g
          "large data: " <> Kernel.to_string(n) <> " bytes"
        end
    end
  end
  defp validate_input(input) do
    if (length(input) == 0) do
      context = "validation"
      if (context == nil) do
        context = ""
      end
      result = {:Error, "Empty input", context}
      this1 = nil
      this1 = result
      this1
    end
    if (length(input) > 1000) do
      context = "validation"
      if (context == nil) do
        context = ""
      end
      result = {:Error, "Input too long", context}
      this1 = nil
      this1 = result
      this1
    end
    value = input.to_lower_case()
    result = {:Success, value}
    this1 = nil
    this1 = result
    this1
  end
  defp process_data(data) do
    if (data.index_of("error") >= 0) do
      context = "processing"
      if (context == nil) do
        context = ""
      end
      result = {:Error, "Data contains error keyword", context}
      this1 = nil
      this1 = result
      this1
    end
    value = data.to_upper_case()
    result = {:Success, value}
    this1 = nil
    this1 = result
    this1
  end
  defp format_output(data) do
    if (length(data) == 0) do
      context = "formatting"
      if (context == nil) do
        context = ""
      end
      result = {:Error, "No data to format", context}
      this1 = nil
      this1 = result
      this1
    end
    result = {:Success, "Formatted: [" <> data <> "]"}
    this1 = nil
    this1 = result
    this1
  end
  def main() do
    Log.trace("Enhanced pattern matching compilation test", %{:file_name => "Main.hx", :line_number => 231, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_status({:Working, "compile"}), %{:file_name => "Main.hx", :line_number => 234, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_status({:Completed, "success", 1500}), %{:file_name => "Main.hx", :line_number => 235, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(incomplete_match({:Failed, "timeout", 2}), %{:file_name => "Main.hx", :line_number => 238, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    result = {:Success, "deep value"}
    this1 = nil
    this1 = result
    value = this1
    result = {:Success, value}
    this1 = nil
    this1 = result
    nested_success = value
this1
    Log.trace(match_nested_result(nested_success), %{:file_name => "Main.hx", :line_number => 242, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_with_complex_guards({:Working, "urgent task"}, 8, true), %{:file_name => "Main.hx", :line_number => 245, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
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
    Log.trace(match_validation_state({:Invalid, ["Required field missing", "Invalid format"]}), %{:file_name => "Main.hx", :line_number => 268, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_validation_state({:Pending, "security_validator"}), %{:file_name => "Main.hx", :line_number => 269, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_binary_pattern("test"), %{:file_name => "Main.hx", :line_number => 272, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
    Log.trace(match_binary_pattern(""), %{:file_name => "Main.hx", :line_number => 273, :class_name => "EnhancedPatternMatchingTest", :method_name => "main"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("haxe/io/bytes.ex", __DIR__)
Code.require_file("enhanced_pattern_matching_test.ex", __DIR__)
EnhancedPatternMatchingTest.main()