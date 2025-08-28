defmodule EnhancedPatternMatchingTest do
  @moduledoc "EnhancedPatternMatchingTest module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe matchStatus"
  def match_status(status) do
    temp_result = nil

    temp_result = nil

    case (case status do :idle -> 0; :working -> 1; :completed -> 2; :failed -> 3; _ -> -1 end) do
      0 -> temp_result = "Currently idle"
      {1, task} -> g_array = elem(status, 1)
    temp_result = "Working on: " <> task
      {2, result, duration} -> g_array = elem(status, 1)
    g_array = elem(status, 2)
    temp_result = "Completed \"" <> result <> "\" in " <> to_string(duration) <> "ms"
      {3, error, retries} -> g_array = elem(status, 1)
    g_array = elem(status, 2)
    temp_result = "Failed with \"" <> error <> "\" after " <> to_string(retries) <> " retries"
    end

    temp_result
  end

  @doc "Generated from Haxe incompleteMatch"
  def incomplete_match(status) do
    temp_result = nil

    case (case status do :idle -> 0; :working -> 1; :completed -> 2; :failed -> 3; _ -> -1 end) do
      0 -> temp_result = "idle"
      {1, task} -> g_array = elem(status, 1)
    temp_result = "working: " <> task
      _ -> temp_result = "unknown"
    end

    temp_result
  end

  @doc "Generated from Haxe matchNestedResult"
  def match_nested_result(result) do
    temp_result = nil

    case ((case result do _ -> -1 end)) do
      _ ->
        g_array = elem(result, 1)
    case (case g_array do :success -> 0; :error -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(g_array, 1)
    temp_result = "Double success: " <> Std.string(value)
      {1, _inner_error, _inner_context} -> g_array = elem(g_array, 1)
    g_array = elem(g_array, 2)
    temp_result = "Outer success, inner error: " <> inner_error <> " (context: " <> inner_context <> ")"
    end
      _ ->
        g_array = elem(result, 1)
    g_array = elem(result, 2)
    outer_error = g_array
    outer_context = g_array
    temp_result = "Outer error: " <> outer_error <> " (context: " <> outer_context <> ")"
    end

    temp_result
  end

  @doc "Generated from Haxe matchWithComplexGuards"
  def match_with_complex_guards(status, priority, is_urgent) do
    temp_result = nil

    case (case status do :idle -> 0; :working -> 1; :completed -> 2; :failed -> 3; _ -> -1 end) do
      0 -> temp_result = "idle"
      {1, task} -> g_array = elem(status, 1)
    if (((priority > 5) && is_urgent)) do
      temp_result = "High priority urgent task: " <> task
    else
      if (((priority > 3) && not is_urgent)) do
        temp_result = "High priority normal task: " <> task
      else
        if (((priority <= 3) && is_urgent)) do
          temp_result = "Low priority urgent task: " <> task
        else
          temp_result = "Normal task: " <> task
        end
      end
    end
      {2, result, _duration} -> g_array = elem(status, 1)
    g_array = elem(status, 2)
    if ((duration < 1000)) do
      temp_result = "Fast completion: " <> result
    else
      if (((duration >= 1000) && (duration < 5000))) do
        temp_result = "Normal completion: " <> result
      else
        temp_result = "Slow completion: " <> result
      end
    end
      {3, error, _retries} -> g_array = elem(status, 1)
    g_array = elem(status, 2)
    if ((retries < 3)) do
      temp_result = "Recoverable failure: " <> error
    else
      temp_result = "Permanent failure: " <> error
    end
    end

    temp_result
  end

  @doc "Generated from Haxe matchWithRangeGuards"
  def match_with_range_guards(value, category) do
    temp_result = nil

    case (category) do
      _ -> cat = category
    n = value
    temp_result = "Unknown category \"" <> cat <> "\" with value " <> to_string(n)
    end

    temp_result
  end

  @doc "Generated from Haxe chainResultOperations"
  def chain_result_operations(input) do
    temp_result = nil
    temp_result1 = nil

    step1 = EnhancedPatternMatchingTest.validate_input(input)

    case ((case step1 do _ -> -1 end)) do
      _ ->
        g_array = elem(step1, 1)
    validated = g_array
    temp_result = EnhancedPatternMatchingTest.process_data(validated)
      _ ->
        g_array = elem(step1, 1)
    g_array = elem(step1, 2)
    error = g_array
    context = g_array
    context = context
    if ((context == nil)), do: context = "", else: nil
    result = DataResult.error(error, context)
    this = nil
    this = result
    temp_result = this
    end

    temp_result1 = nil

    case ((case temp_result do _ -> -1 end)) do
      _ ->
        g_array = elem(temp_result, 1)
    processed = g_array
    temp_result1 = EnhancedPatternMatchingTest.format_output(processed)
      _ ->
        g_array = elem(temp_result, 1)
    g_array = elem(temp_result, 2)
    error = g_array
    context = g_array
    context = context
    if ((context == nil)), do: context = "", else: nil
    result = DataResult.error(error, context)
    this = nil
    this = result
    temp_result1 = this
    end

    temp_result1
  end

  @doc "Generated from Haxe matchArrayPatterns"
  def match_array_patterns(arr) do
    temp_result = nil

    case (arr.length) do
      _ ->
        temp_result = "empty array"
      _ ->
        g_array = Enum.at(arr, 0)
    x = g_array
    temp_result = "single element: " <> to_string(x)
      _ ->
        g_array = Enum.at(arr, 0)
    g_array = Enum.at(arr, 1)
    x = g_array
    y = g_array
    temp_result = "pair: [" <> to_string(x) <> ", " <> to_string(y) <> "]"
      _ ->
        g_array = Enum.at(arr, 0)
    g_array = Enum.at(arr, 1)
    g_array = Enum.at(arr, 2)
    x = g_array
    y = g_array
    z = g_array
    temp_result = "triple: [" <> to_string(x) <> ", " <> to_string(y) <> ", " <> to_string(z) <> "]"
      _ -> a = arr
    if ((a.length > 3)), do: temp_result = "starts with " <> to_string(Enum.at(a, 0)) <> ", has " <> to_string(((a.length - 1))) <> " more elements", else: temp_result = "other array pattern"
    end

    temp_result
  end

  @doc "Generated from Haxe matchStringPatterns"
  def match_string_patterns(input) do
    temp_result = nil

    if ((input == "")) do
      temp_result = "empty string"
    else
      s = input
      if ((s.length == 1)) do
        temp_result = "single character: \"" <> s <> "\""
      else
        s = input
        if ((s.substr(0, 7) == "prefix_")) do
          temp_result = "has prefix: \"" <> s <> "\""
        else
          s = input
          if ((s.substr((s.length - 7)) == "_suffix")) do
            temp_result = "has suffix: \"" <> s <> "\""
          else
            s = input
            if ((s.index_of("@") > -1)) do
              temp_result = "contains @: \"" <> s <> "\""
            else
              s = input
              if ((s.length > 100)) do
                temp_result = "very long string"
              else
                s = input
                temp_result = "regular string: \"" <> s <> "\""
              end
            end
          end
        end
      end
    end

    temp_result
  end

  @doc "Generated from Haxe matchObjectPatterns"
  def match_object_patterns(data) do
    temp_result = nil

    g_array = data.name
    g_array = data.age
    g_array = data.active
    case (g_array) do
      _ -> temp_result = "unknown pattern"
    end

    temp_result
  end

  @doc "Generated from Haxe matchValidationState"
  def match_validation_state(state) do
    temp_result = nil

    case (case state do :valid -> 0; :invalid -> 1; :pending -> 2; _ -> -1 end) do
      0 -> temp_result = "Data is valid"
      {1, _errors} -> g_array = elem(state, 1)
    if ((errors.length == 1)) do
      temp_result = "Single error: " <> Enum.at(errors, 0)
    else
      if ((errors.length > 1)) do
        temp_result = "Multiple errors: " <> to_string(errors.length) <> " issues"
      else
        temp_result = "No specific errors"
      end
    end
      {2, validator} -> g_array = elem(state, 1)
    temp_result = "Validation pending by: " <> validator
    end

    temp_result
  end

  @doc "Generated from Haxe matchBinaryPattern"
  def match_binary_pattern(data) do
    temp_result = nil

    bytes = Bytes.of_string(data)

    g_array = bytes.length
    case (g_array) do
      _ ->
        "empty"
      _ ->
        "single byte: " <> to_string(Enum.at(bytes.b, 0))
      _ -> n = g_array
    if ((n <= 4)) do
      temp_result = "small data: " <> to_string(n) <> " bytes"
    else
      n = g_array
      temp_result = "large data: " <> to_string(n) <> " bytes"
    end
    end

    temp_result
  end

  @doc "Generated from Haxe validateInput"
  def validate_input(input) do
    temp_result = nil
    temp_result1 = nil
    temp_result2 = nil

    if ((input.length == 0)) do
      context = "validation"
      if ((context == nil)), do: context = "", else: nil
      result = DataResult.error("Empty input", context)
      this = nil
      this = result
      temp_result = this
      temp_result
    else
      nil
    end

    if ((input.length > 1000)) do
      context = "validation"
      if ((context == nil)), do: context = "", else: nil
      result = DataResult.error("Input too long", context)
      this = nil
      this = result
      temp_result1 = this
      temp_result1
    else
      nil
    end

    temp_result2 = nil

    value = input.to_lower_case()

    result = DataResult.success(value)
    temp_result2 = result

    temp_result2
  end

  @doc "Generated from Haxe processData"
  def process_data(data) do
    temp_result = nil
    temp_result1 = nil

    if ((data.index_of("error") >= 0)) do
      context = "processing"
      if ((context == nil)), do: context = "", else: nil
      result = DataResult.error("Data contains error keyword", context)
      this = nil
      this = result
      temp_result = this
      temp_result
    else
      nil
    end

    value = data.to_upper_case()

    result = DataResult.success(value)
    temp_result1 = result

    temp_result1
  end

  @doc "Generated from Haxe formatOutput"
  def format_output(data) do
    temp_result = nil
    temp_result1 = nil

    if ((data.length == 0)) do
      context = "formatting"
      if ((context == nil)), do: context = "", else: nil
      result = DataResult.error("No data to format", context)
      this = nil
      this = result
      temp_result = this
      temp_result
    else
      nil
    end

    result = DataResult.success("Formatted: [" <> data <> "]")
    temp_result1 = result

    temp_result1
  end

  @doc "Generated from Haxe main"
  def main() do
    temp_result1 = nil
    temp_result = nil

    Log.trace("Enhanced pattern matching compilation test", %{"fileName" => "Main.hx", "lineNumber" => 231, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_status(Status.working("compile")), %{"fileName" => "Main.hx", "lineNumber" => 234, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_status(Status.completed("success", 1500)), %{"fileName" => "Main.hx", "lineNumber" => 235, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.incomplete_match(Status.failed("timeout", 2)), %{"fileName" => "Main.hx", "lineNumber" => 238, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    result = DataResult.success("deep value")
    temp_result1 = result

    result = DataResult.success(temp_result1)
    temp_result = result

    Log.trace(EnhancedPatternMatchingTest.match_nested_result(temp_result), %{"fileName" => "Main.hx", "lineNumber" => 242, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_with_complex_guards(Status.working("urgent task"), 8, true), %{"fileName" => "Main.hx", "lineNumber" => 245, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_with_range_guards(85, "score"), %{"fileName" => "Main.hx", "lineNumber" => 248, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_with_range_guards(25, "temperature"), %{"fileName" => "Main.hx", "lineNumber" => 249, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.chain_result_operations("valid input"), %{"fileName" => "Main.hx", "lineNumber" => 252, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.chain_result_operations(""), %{"fileName" => "Main.hx", "lineNumber" => 253, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_array_patterns([1, 2, 3, 4, 5]), %{"fileName" => "Main.hx", "lineNumber" => 256, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_array_patterns([]), %{"fileName" => "Main.hx", "lineNumber" => 257, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_string_patterns("prefix_test"), %{"fileName" => "Main.hx", "lineNumber" => 260, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_string_patterns("test@example.com"), %{"fileName" => "Main.hx", "lineNumber" => 261, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_object_patterns(%{"name" => "Alice", "age" => 25, "active" => true}), %{"fileName" => "Main.hx", "lineNumber" => 264, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_object_patterns(%{"name" => "Bob", "age" => 16, "active" => true}), %{"fileName" => "Main.hx", "lineNumber" => 265, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_validation_state(ValidationState.invalid(["Required field missing", "Invalid format"])), %{"fileName" => "Main.hx", "lineNumber" => 268, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_validation_state(ValidationState.pending("security_validator")), %{"fileName" => "Main.hx", "lineNumber" => 269, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_binary_pattern("test"), %{"fileName" => "Main.hx", "lineNumber" => 272, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})

    Log.trace(EnhancedPatternMatchingTest.match_binary_pattern(""), %{"fileName" => "Main.hx", "lineNumber" => 273, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
  end

end
