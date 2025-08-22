defmodule EnhancedPatternMatchingTest do
  @moduledoc "EnhancedPatternMatchingTest module generated from Haxe"

  # Static functions
  @doc """
    Test exhaustive pattern matching with all enum cases
    Should generate all possible case clauses
  """
  @spec match_status(Status.t()) :: String.t()
  def match_status(status) do
    (
          temp_result = nil
          case (elem(status, 0)) do
      0 -> temp_result = "Currently idle"
      1 -> (
          g = elem(status, 1)
          task = g
          temp_result = "Working on: " <> task
        )
      2 -> (
          g = elem(status, 1)
          g = elem(status, 2)
          result = g
          duration = g
          temp_result = "Completed \"" <> result <> "\" in " <> to_string(duration) <> "ms"
        )
      3 -> (
          g = elem(status, 1)
          g = elem(status, 2)
          error = g
          retries = g
          temp_result = "Failed with \"" <> error <> "\" after " <> to_string(retries) <> " retries"
        )
    end
          temp_result
        )
  end

  @doc """
    Test partial pattern matching (missing cases) - should generate warning
    Intentionally incomplete for exhaustive checking test
  """
  @spec incomplete_match(Status.t()) :: String.t()
  def incomplete_match(status) do
    (
          temp_result = nil
          case (elem(status, 0)) do
      0 -> temp_result = "idle"
      1 -> (
          g = elem(status, 1)
          task = g
          temp_result = "working: " <> task
        )
      _ -> temp_result = "unknown"
    end
          temp_result
        )
  end

  @doc """
    Test nested pattern matching with complex destructuring

  """
  @spec match_nested_result(Result.t()) :: String.t()
  def match_nested_result(result) do
    (
          temp_result = nil
          case (elem(result, 0)) do
      0 -> (
          g = elem(result, 1)
          case (elem(g, 0)) do
      0 -> (
          g = elem(g, 1)
          value = g
          temp_result = "Double success: " <> Std.string(value)
        )
      1 -> (
          g = elem(g, 1)
          g = elem(g, 2)
          inner_error = g
          inner_context = g
          temp_result = "Outer success, inner error: " <> inner_error <> " (context: " <> inner_context <> ")"
        )
    end
        )
      1 -> (
          g = elem(result, 1)
          g = elem(result, 2)
          outer_error = g
          outer_context = g
          temp_result = "Outer error: " <> outer_error <> " (context: " <> outer_context <> ")"
        )
    end
          temp_result
        )
  end

  @doc """
    Test complex guards with multiple conditions and logical operators

  """
  @spec match_with_complex_guards(Status.t(), integer(), boolean()) :: String.t()
  def match_with_complex_guards(status, priority, is_urgent) do
    (
          temp_result = nil
          case (elem(status, 0)) do
      0 -> temp_result = "idle"
      1 -> (
          g = elem(status, 1)
          task = g
          if (((priority > 5) && is_urgent)) do
          temp_result = "High priority urgent task: " <> task
        else
          (
          task = g
          if (((priority > 3) && not is_urgent)) do
          temp_result = "High priority normal task: " <> task
        else
          (
          task = g
          if (((priority <= 3) && is_urgent)) do
          temp_result = "Low priority urgent task: " <> task
        else
          (
          task = g
          temp_result = "Normal task: " <> task
        )
        end
        )
        end
        )
        end
        )
      2 -> (
          g = elem(status, 1)
          g = elem(status, 2)
          result = g
          duration = g
          if ((duration < 1000)) do
          temp_result = "Fast completion: " <> result
        else
          (
          result = g
          duration = g
          if (((duration >= 1000) && (duration < 5000))) do
          temp_result = "Normal completion: " <> result
        else
          (
          result = g
          g
          temp_result = "Slow completion: " <> result
        )
        end
        )
        end
        )
      3 -> (
          g = elem(status, 1)
          g = elem(status, 2)
          error = g
          retries = g
          if ((retries < 3)) do
          temp_result = "Recoverable failure: " <> error
        else
          (
          error = g
          g
          temp_result = "Permanent failure: " <> error
        )
        end
        )
    end
          temp_result
        )
  end

  @doc """
    Test range guards and membership tests

  """
  @spec match_with_range_guards(integer(), String.t()) :: String.t()
  def match_with_range_guards(value, category) do
    (
          temp_result = nil
          case (category) do
      "score" -> (
          n = value
          if ((n >= 90)) do
          temp_result = "Excellent score"
        else
          (
          n = value
          if (((n >= 70) && (n < 90))) do
          temp_result = "Good score"
        else
          (
          n = value
          if (((n >= 50) && (n < 70))) do
          temp_result = "Average score"
        else
          (
          n = value
          if ((n < 50)) do
          temp_result = "Poor score"
        else
          (
          cat = category
          n = value
          temp_result = "Unknown category \"" <> cat <> "\" with value " <> to_string(n)
        )
        end
        )
        end
        )
        end
        )
        end
        )
      "temperature" -> (
          n = value
          if ((n >= 30)) do
          temp_result = "Hot"
        else
          (
          n = value
          if (((n >= 20) && (n < 30))) do
          temp_result = "Warm"
        else
          (
          n = value
          if (((n >= 10) && (n < 20))) do
          temp_result = "Cool"
        else
          (
          n = value
          if ((n < 10)) do
          temp_result = "Cold"
        else
          (
          cat = category
          n = value
          temp_result = "Unknown category \"" <> cat <> "\" with value " <> to_string(n)
        )
        end
        )
        end
        )
        end
        )
        end
        )
      _ -> (
          cat = category
          n = value
          temp_result = "Unknown category \"" <> cat <> "\" with value " <> to_string(n)
        )
    end
          temp_result
        )
  end

  @doc """
    Test Result patterns that should generate with statements
    This should demonstrate Elixir's with statement generation
  """
  @spec chain_result_operations(String.t()) :: Result.t()
  def chain_result_operations(input) do
    (
          step1 = EnhancedPatternMatchingTest.validate_input(input)
          temp_result = nil
          case (elem(step1, 0)) do
      0 -> (
          g = elem(step1, 1)
          validated = g
          temp_result = EnhancedPatternMatchingTest.process_data(validated)
        )
      1 -> (
          g = elem(step1, 1)
          g = elem(step1, 2)
          (
          error = g
          context = g
          (
          context = context
          if ((context == nil)) do
          context = ""
        end
          (
          result = DataResult.error(error, context)
          this = nil
          this = result
          temp_result = this
        )
        )
        )
        )
    end
          temp_result1 = nil
          case (elem(temp_result, 0)) do
      0 -> (
          g = elem(temp_result, 1)
          processed = g
          temp_result1 = EnhancedPatternMatchingTest.format_output(processed)
        )
      1 -> (
          g = elem(temp_result, 1)
          g = elem(temp_result, 2)
          (
          error = g
          context = g
          (
          context = context
          if ((context == nil)) do
          context = ""
        end
          (
          result = DataResult.error(error, context)
          this = nil
          this = result
          temp_result1 = this
        )
        )
        )
        )
    end
          temp_result1
        )
  end

  @doc """
    Test array patterns with length-based matching

  """
  @spec match_array_patterns(Array.t()) :: String.t()
  def match_array_patterns(arr) do
    (
          temp_result = nil
          case (arr.length) do
      0 -> temp_result = "empty array"
      1 -> (
          g = Enum.at(arr, 0)
          (
          x = g
          temp_result = "single element: " <> to_string(x)
        )
        )
      2 -> (
          g = Enum.at(arr, 0)
          g = Enum.at(arr, 1)
          (
          x = g
          y = g
          temp_result = "pair: [" <> to_string(x) <> ", " <> to_string(y) <> "]"
        )
        )
      3 -> (
          g = Enum.at(arr, 0)
          g = Enum.at(arr, 1)
          g = Enum.at(arr, 2)
          (
          x = g
          y = g
          z = g
          temp_result = "triple: [" <> to_string(x) <> ", " <> to_string(y) <> ", " <> to_string(z) <> "]"
        )
        )
      _ -> (
          a = arr
          if ((a.length > 3)) do
          temp_result = "starts with " <> to_string(Enum.at(a, 0)) <> ", has " <> to_string(((a.length - 1))) <> " more elements"
        else
          temp_result = "other array pattern"
        end
        )
    end
          temp_result
        )
  end

  @doc """
    Test string patterns with complex conditions

  """
  @spec match_string_patterns(String.t()) :: String.t()
  def match_string_patterns(input) do
    (
          temp_result = nil
          if ((input == "")) do
          temp_result = "empty string"
        else
          (
          s = input
          if ((s.length == 1)) do
          temp_result = "single character: \"" <> s <> "\""
        else
          (
          s = input
          if ((s.substr(0, 7) == "prefix_")) do
          temp_result = "has prefix: \"" <> s <> "\""
        else
          (
          s = input
          if ((s.substr((s.length - 7)) == "_suffix")) do
          temp_result = "has suffix: \"" <> s <> "\""
        else
          (
          s = input
          if ((s.index_of("@") > -1)) do
          temp_result = "contains @: \"" <> s <> "\""
        else
          (
          s = input
          if ((s.length > 100)) do
          temp_result = "very long string"
        else
          (
          s = input
          temp_result = "regular string: \"" <> s <> "\""
        )
        end
        )
        end
        )
        end
        )
        end
        )
        end
        )
        end
          temp_result
        )
  end

  @doc """
    Test tuple/object patterns with field matching

  """
  @spec match_object_patterns(term()) :: String.t()
  def match_object_patterns(data) do
    (
          temp_result = nil
          (
          g = data.name
          g = data.age
          g = data.active
          case (g) do
      false -> (
          age = g
          name = g
          temp_result = "Inactive user: " <> name <> " (" <> to_string(age) <> ")"
        )
      true -> (
          age = g
          name = g
          if ((age >= 18)) do
          temp_result = "Active adult: " <> name <> " (" <> to_string(age) <> ")"
        else
          (
          age = g
          name = g
          if ((age < 18)) do
          temp_result = "Active minor: " <> name <> " (" <> to_string(age) <> ")"
        else
          temp_result = "unknown pattern"
        end
        )
        end
        )
      _ -> temp_result = "unknown pattern"
    end
        )
          temp_result
        )
  end

  @doc """
    Test enum patterns with validation state

  """
  @spec match_validation_state(ValidationState.t()) :: String.t()
  def match_validation_state(state) do
    (
          temp_result = nil
          case (elem(state, 0)) do
      0 -> temp_result = "Data is valid"
      1 -> (
          g = elem(state, 1)
          errors = g
          if ((errors.length == 1)) do
          temp_result = "Single error: " <> Enum.at(errors, 0)
        else
          (
          errors = g
          if ((errors.length > 1)) do
          temp_result = "Multiple errors: " <> to_string(errors.length) <> " issues"
        else
          (
          g
          temp_result = "No specific errors"
        )
        end
        )
        end
        )
      2 -> (
          g = elem(state, 1)
          validator = g
          temp_result = "Validation pending by: " <> validator
        )
    end
          temp_result
        )
  end

  @doc """
    Test binary patterns for byte matching (if supported)

  """
  @spec match_binary_pattern(String.t()) :: String.t()
  def match_binary_pattern(data) do
    (
          bytes = Bytes.of_string(data)
          temp_result = nil
          (
          g = bytes.length
          case (g) do
      0 -> temp_result = "empty"
      1 -> temp_result = "single byte: " <> to_string(Enum.at(bytes.b, 0))
      _ -> (
          n = g
          if ((n <= 4)) do
          temp_result = "small data: " <> to_string(n) <> " bytes"
        else
          (
          n = g
          temp_result = "large data: " <> to_string(n) <> " bytes"
        )
        end
        )
    end
        )
          temp_result
        )
  end

  @doc "Function validate_input"
  @spec validate_input(String.t()) :: Result.t()
  def validate_input(input) do
    (
          if ((input.length == 0)) do
          (
          temp_result = nil
          (
          context = "validation"
          if ((context == nil)) do
          context = ""
        end
          (
          result = DataResult.error("Empty input", context)
          this = nil
          this = result
          temp_result = this
        )
        )
          temp_result
        )
        end
          if ((input.length > 1000)) do
          (
          temp_result1 = nil
          (
          context = "validation"
          if ((context == nil)) do
          context = ""
        end
          (
          result = DataResult.error("Input too long", context)
          this = nil
          this = result
          temp_result1 = this
        )
        )
          temp_result1
        )
        end
          temp_result2 = nil
          value = input.to_lower_case()
          (
          result = DataResult.success(value)
          temp_result2 = result
        )
          temp_result2
        )
  end

  @doc "Function process_data"
  @spec process_data(String.t()) :: Result.t()
  def process_data(data) do
    (
          if ((data.index_of("error") >= 0)) do
          (
          temp_result = nil
          context = "processing"
          if ((context == nil)) do
          context = ""
        end
          (
          result = DataResult.error("Data contains error keyword", context)
          this = nil
          this = result
          temp_result = this
        )
          temp_result
        )
        end
          temp_result1 = nil
          value = data.to_upper_case()
          (
          result = DataResult.success(value)
          temp_result1 = result
        )
          temp_result1
        )
  end

  @doc "Function format_output"
  @spec format_output(String.t()) :: Result.t()
  def format_output(data) do
    (
          if ((data.length == 0)) do
          (
          temp_result = nil
          context = "formatting"
          if ((context == nil)) do
          context = ""
        end
          (
          result = DataResult.error("No data to format", context)
          this = nil
          this = result
          temp_result = this
        )
          temp_result
        )
        end
          temp_result1 = nil
          (
          result = DataResult.success("Formatted: [" <> data <> "]")
          temp_result1 = result
        )
          temp_result1
        )
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("Enhanced pattern matching compilation test", %{"fileName" => "Main.hx", "lineNumber" => 231, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_status(Status.working("compile")), %{"fileName" => "Main.hx", "lineNumber" => 234, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.match_status(Status.completed("success", 1500)), %{"fileName" => "Main.hx", "lineNumber" => 235, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.incomplete_match(Status.failed("timeout", 2)), %{"fileName" => "Main.hx", "lineNumber" => 238, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    temp_result = nil
    temp_result1 = nil
    (
          result = DataResult.success("deep value")
          temp_result1 = result
        )
    (
          result = DataResult.success(temp_result1)
          temp_result = result
        )
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
