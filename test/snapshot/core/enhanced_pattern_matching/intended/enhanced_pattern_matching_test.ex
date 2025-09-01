defmodule EnhancedPatternMatchingTest do
  def match_status(status) do
    case (status.elem(0)) do
      0 ->
        "Currently idle"
      1 ->
        g = status.elem(1)
        task = g
        "Working on: " + task
      2 ->
        g = status.elem(1)
        g1 = status.elem(2)
        result = g
        duration = g1
        "Completed \"" + result + "\" in " + duration + "ms"
      3 ->
        g = status.elem(1)
        g1 = status.elem(2)
        error = g
        retries = g1
        "Failed with \"" + error + "\" after " + retries + " retries"
    end
  end
  def incomplete_match(status) do
    case (status.elem(0)) do
      0 ->
        "idle"
      1 ->
        g = status.elem(1)
        task = g
        "working: " + task
      _ ->
        "unknown"
    end
  end
  def match_nested_result(result) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        case (g.elem(0)) do
          0 ->
            g = g.elem(1)
            value = g
            "Double success: " + Std.string(value)
          1 ->
            g1 = g.elem(1)
            g = g.elem(2)
            inner_error = g1
            inner_context = g
            "Outer success, inner error: " + inner_error + " (context: " + inner_context + ")"
        end
      1 ->
        g = result.elem(1)
        g1 = result.elem(2)
        outer_error = g
        outer_context = g1
        "Outer error: " + outer_error + " (context: " + outer_context + ")"
    end
  end
  def match_with_complex_guards(status, priority, is_urgent) do
    case (status.elem(0)) do
      0 ->
        "idle"
      1 ->
        g = status.elem(1)
        task = g
        if (priority > 5 && is_urgent) do
          "High priority urgent task: " + task
        else
          task = g
          if (priority > 3 && not is_urgent) do
            "High priority normal task: " + task
          else
            task = g
            if (priority <= 3 && is_urgent) do
              "Low priority urgent task: " + task
            else
              task = g
              "Normal task: " + task
            end
          end
        end
      2 ->
        g = status.elem(1)
        g1 = status.elem(2)
        result = g
        duration = g1
        if (duration < 1000) do
          "Fast completion: " + result
        else
          result = g
          duration = g1
          if (duration >= 1000 && duration < 5000) do
            "Normal completion: " + result
          else
            result = g
            duration = g1
            "Slow completion: " + result
          end
        end
      3 ->
        g = status.elem(1)
        g1 = status.elem(2)
        error = g
        retries = g1
        if (retries < 3) do
          "Recoverable failure: " + error
        else
          error = g
          retries = g1
          "Permanent failure: " + error
        end
    end
  end
  def match_with_range_guards(value, category) do
    case (category) do
      "score" ->
        n = value
        if (n >= 90) do
          "Excellent score"
        else
          n = value
          if (n >= 70 && n < 90) do
            "Good score"
          else
            n = value
            if (n >= 50 && n < 70) do
              "Average score"
            else
              n = value
              if (n < 50) do
                "Poor score"
              else
                cat = category
                n = value
                "Unknown category \"" + cat + "\" with value " + n
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
          if (n >= 20 && n < 30) do
            "Warm"
          else
            n = value
            if (n >= 10 && n < 20) do
              "Cool"
            else
              n = value
              if (n < 10) do
                "Cold"
              else
                cat = category
                n = value
                "Unknown category \"" + cat + "\" with value " + n
              end
            end
          end
        end
      _ ->
        cat = category
        n = value
        "Unknown category \"" + cat + "\" with value " + n
    end
  end
  def chain_result_operations(input) do
    step_1 = EnhancedPatternMatchingTest.validate_input(input)
    step_2 = case (step.elem(0)) do
  0 ->
    g = step.elem(1)
    validated = g
    EnhancedPatternMatchingTest.process_data(validated)
  1 ->
    g = step.elem(1)
    g1 = step.elem(2)
    error = g
    context = g1
    context = context
    if (context == nil) do
      context = ""
    end
    result = {:Error, error, context}
    this_1 = nil
    this_1 = result
    this_1
end
    step_3 = case (step.elem(0)) do
  0 ->
    g = step.elem(1)
    processed = g
    EnhancedPatternMatchingTest.format_output(processed)
  1 ->
    g = step.elem(1)
    g1 = step.elem(2)
    error = g
    context = g1
    context = context
    if (context == nil) do
      context = ""
    end
    result = {:Error, error, context}
    this_1 = nil
    this_1 = result
    this_1
end
    step
  end
  def match_array_patterns(arr) do
    case (arr.length) do
      0 ->
        "empty array"
      1 ->
        g = arr[0]
        x = g
        "single element: " + x
      2 ->
        g = arr[0]
        g1 = arr[1]
        x = g
        y = g1
        "pair: [" + x + ", " + y + "]"
      3 ->
        g = arr[0]
        g1 = arr[1]
        g2 = arr[2]
        x = g
        y = g1
        z = g2
        "triple: [" + x + ", " + y + ", " + z + "]"
      _ ->
        a = arr
        if (a.length > 3) do
          "starts with " + a[0] + ", has " + (a.length - 1) + " more elements"
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
      if (s.length == 1) do
        "single character: \"" + s + "\""
      else
        s = input
        if (s.substr(0, 7) == "prefix_") do
          "has prefix: \"" + s + "\""
        else
          s = input
          if (s.substr(s.length - 7) == "_suffix") do
            "has suffix: \"" + s + "\""
          else
            s = input
            if (s.indexOf("@") > -1) do
              "contains @: \"" + s + "\""
            else
              s = input
              if (s.length > 100) do
                "very long string"
              else
                s = input
                "regular string: \"" + s + "\""
              end
            end
          end
        end
      end
    end
  end
  def match_object_patterns(data) do
    g = data[:name]
    g1 = data[:age]
    g2 = data[:active]
    case (g2) do
      false ->
        age = g1
        name = g
        "Inactive user: " + name + " (" + age + ")"
      true ->
        age = g1
        name = g
        if (age >= 18) do
          "Active adult: " + name + " (" + age + ")"
        else
          age = g1
          name = g
          if (age < 18), do: "Active minor: " + name + " (" + age + ")", else: "unknown pattern"
        end
      _ ->
        "unknown pattern"
    end
  end
  def match_validation_state(state) do
    case (state.elem(0)) do
      0 ->
        "Data is valid"
      1 ->
        g = state.elem(1)
        errors = g
        if (errors.length == 1) do
          "Single error: " + errors[0]
        else
          errors = g
          if (errors.length > 1) do
            "Multiple errors: " + errors.length + " issues"
          else
            errors = g
            "No specific errors"
          end
        end
      2 ->
        g = state.elem(1)
        validator = g
        "Validation pending by: " + validator
    end
  end
  def match_binary_pattern(data) do
    bytes = Bytes.of_string(data)
    g = bytes.length
    case (g) do
      0 ->
        "empty"
      1 ->
        "single byte: " + bytes.b[0]
      _ ->
        n = g
        if (n <= 4) do
          "small data: " + n + " bytes"
        else
          n = g
          "large data: " + n + " bytes"
        end
    end
  end
  defp validate_input(input) do
    if (input.length == 0) do
      context = "validation"
      if (context == nil) do
        context = ""
      end
      result = {:Error, "Empty input", context}
      this_1 = nil
      this_1 = result
      this_1
    end
    if (input.length > 1000) do
      context = "validation"
      if (context == nil) do
        context = ""
      end
      result = {:Error, "Input too long", context}
      this_1 = nil
      this_1 = result
      this_1
    end
    value = input.toLowerCase()
    result = {:Success, value}
    this_1 = nil
    this_1 = result
    this_1
  end
  defp process_data(data) do
    if (data.indexOf("error") >= 0) do
      context = "processing"
      if (context == nil) do
        context = ""
      end
      result = {:Error, "Data contains error keyword", context}
      this_1 = nil
      this_1 = result
      this_1
    end
    value = data.toUpperCase()
    result = {:Success, value}
    this_1 = nil
    this_1 = result
    this_1
  end
  defp format_output(data) do
    if (data.length == 0) do
      context = "formatting"
      if (context == nil) do
        context = ""
      end
      result = {:Error, "No data to format", context}
      this_1 = nil
      this_1 = result
      this_1
    end
    result = {:Success, "Formatted: [" + data + "]"}
    this_1 = nil
    this_1 = result
    this_1
  end
  def main() do
    Log.trace("Enhanced pattern matching compilation test", %{:fileName => "Main.hx", :lineNumber => 231, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_status({:Working, "compile"}), %{:fileName => "Main.hx", :lineNumber => 234, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_status({:Completed, "success", 1500}), %{:fileName => "Main.hx", :lineNumber => 235, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.incomplete_match({:Failed, "timeout", 2}), %{:fileName => "Main.hx", :lineNumber => 238, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    nested_success = value = result = {:Success, "deep value"}
this_1 = nil
this_1 = result
this_1
result = {:Success, value}
this_1 = nil
this_1 = result
this_1
    Log.trace(EnhancedPatternMatchingTest.match_nested_result(nested_success), %{:fileName => "Main.hx", :lineNumber => 242, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_with_complex_guards({:Working, "urgent task"}, 8, true), %{:fileName => "Main.hx", :lineNumber => 245, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_with_range_guards(85, "score"), %{:fileName => "Main.hx", :lineNumber => 248, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_with_range_guards(25, "temperature"), %{:fileName => "Main.hx", :lineNumber => 249, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.chain_result_operations("valid input"), %{:fileName => "Main.hx", :lineNumber => 252, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.chain_result_operations(""), %{:fileName => "Main.hx", :lineNumber => 253, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_array_patterns([1, 2, 3, 4, 5]), %{:fileName => "Main.hx", :lineNumber => 256, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_array_patterns([]), %{:fileName => "Main.hx", :lineNumber => 257, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_string_patterns("prefix_test"), %{:fileName => "Main.hx", :lineNumber => 260, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_string_patterns("test@example.com"), %{:fileName => "Main.hx", :lineNumber => 261, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_object_patterns(%{:name => "Alice", :age => 25, :active => true}), %{:fileName => "Main.hx", :lineNumber => 264, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_object_patterns(%{:name => "Bob", :age => 16, :active => true}), %{:fileName => "Main.hx", :lineNumber => 265, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_validation_state({:Invalid, ["Required field missing", "Invalid format"]}), %{:fileName => "Main.hx", :lineNumber => 268, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_validation_state({:Pending, "security_validator"}), %{:fileName => "Main.hx", :lineNumber => 269, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_binary_pattern("test"), %{:fileName => "Main.hx", :lineNumber => 272, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_binary_pattern(""), %{:fileName => "Main.hx", :lineNumber => 273, :className => "EnhancedPatternMatchingTest", :methodName => "main"})
  end
end