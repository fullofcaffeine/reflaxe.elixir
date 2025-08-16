defmodule EnhancedPatternMatchingTest do
  @moduledoc """
  EnhancedPatternMatchingTest module generated from Haxe
  """

  # Static functions
  @doc """
    Test exhaustive pattern matching with all enum cases
    Should generate all possible case clauses
  """
  @spec match_status(Status.t()) :: String.t()
  def match_status(status) do
    temp_result = nil
    case (elem(status, 0)) do
      0 ->
        temp_result = "Currently idle"
      1 ->
        _g = elem(status, 1)
        task = _g
        temp_result = "Working on: " <> task
      2 ->
        _g = elem(status, 1)
        _g = elem(status, 2)
        result = _g
        duration = _g
        temp_result = "Completed \"" <> result <> "\" in " <> Integer.to_string(duration) <> "ms"
      3 ->
        _g = elem(status, 1)
        _g = elem(status, 2)
        error = _g
        retries = _g
        temp_result = "Failed with \"" <> error <> "\" after " <> Integer.to_string(retries) <> " retries"
    end
    temp_result
  end

  @doc """
    Test partial pattern matching (missing cases) - should generate warning
    Intentionally incomplete for exhaustive checking test
  """
  @spec incomplete_match(Status.t()) :: String.t()
  def incomplete_match(status) do
    temp_result = nil
    case (elem(status, 0)) do
      0 ->
        temp_result = "idle"
      1 ->
        _g = elem(status, 1)
        task = _g
        temp_result = "working: " <> task
      _ ->
        temp_result = "unknown"
    end
    temp_result
  end

  @doc """
    Test nested pattern matching with complex destructuring

  """
  @spec match_nested_result(Result.t()) :: String.t()
  def match_nested_result(result) do
    temp_result = nil
    case (elem(result, 0)) do
      0 ->
        _g = elem(result, 1)
        case (elem(_g, 0)) do
          0 ->
            _g = elem(_g, 1)
            value = _g
            temp_result = "Double success: " <> Std.string(value)
          1 ->
            _g = elem(_g, 1)
            _g = elem(_g, 2)
            inner_error = _g
            inner_context = _g
            temp_result = "Outer success, inner error: " <> inner_error <> " (context: " <> inner_context <> ")"
        end
      1 ->
        _g = elem(result, 1)
        _g = elem(result, 2)
        outer_error = _g
        outer_context = _g
        temp_result = "Outer error: " <> outer_error <> " (context: " <> outer_context <> ")"
    end
    temp_result
  end

  @doc """
    Test complex guards with multiple conditions and logical operators

  """
  @spec match_with_complex_guards(Status.t(), integer(), boolean()) :: String.t()
  def match_with_complex_guards(status, priority, is_urgent) do
    temp_result = nil
    case (elem(status, 0)) do
      0 ->
        temp_result = "idle"
      1 ->
        _g = elem(status, 1)
        task = _g
        if (priority > 5 && is_urgent) do
          temp_result = "High priority urgent task: " <> task
        else
          task = _g
          if (priority > 3 && !is_urgent) do
            temp_result = "High priority normal task: " <> task
          else
            task = _g
            if (priority <= 3 && is_urgent) do
              temp_result = "Low priority urgent task: " <> task
            else
              task = _g
              temp_result = "Normal task: " <> task
            end
          end
        end
      2 ->
        _g = elem(status, 1)
        _g = elem(status, 2)
        result = _g
        duration = _g
        if (duration < 1000) do
          temp_result = "Fast completion: " <> result
        else
          result = _g
          duration = _g
          if (duration >= 1000 && duration < 5000) do
            temp_result = "Normal completion: " <> result
          else
            result = _g
            _g
            temp_result = "Slow completion: " <> result
          end
        end
      3 ->
        _g = elem(status, 1)
        _g = elem(status, 2)
        error = _g
        retries = _g
        if (retries < 3) do
          temp_result = "Recoverable failure: " <> error
        else
          error = _g
          _g
          temp_result = "Permanent failure: " <> error
        end
    end
    temp_result
  end

  @doc """
    Test range guards and membership tests

  """
  @spec match_with_range_guards(integer(), String.t()) :: String.t()
  def match_with_range_guards(value, category) do
    temp_result = nil
    case (category) do
      "score" ->
        n = value
        if (n >= 90) do
          temp_result = "Excellent score"
        else
          n = value
          if (n >= 70 && n < 90) do
            temp_result = "Good score"
          else
            n = value
            if (n >= 50 && n < 70) do
              temp_result = "Average score"
            else
              n = value
              if (n < 50) do
                temp_result = "Poor score"
              else
                cat = category
                n = value
                temp_result = "Unknown category \"" <> cat <> "\" with value " <> Integer.to_string(n)
              end
            end
          end
        end
      "temperature" ->
        n = value
        if (n >= 30) do
          temp_result = "Hot"
        else
          n = value
          if (n >= 20 && n < 30) do
            temp_result = "Warm"
          else
            n = value
            if (n >= 10 && n < 20) do
              temp_result = "Cool"
            else
              n = value
              if (n < 10) do
                temp_result = "Cold"
              else
                cat = category
                n = value
                temp_result = "Unknown category \"" <> cat <> "\" with value " <> Integer.to_string(n)
              end
            end
          end
        end
      _ ->
        cat = category
        n = value
        temp_result = "Unknown category \"" <> cat <> "\" with value " <> Integer.to_string(n)
    end
    temp_result
  end

  @doc """
    Test Result patterns that should generate with statements
    This should demonstrate Elixir's with statement generation
  """
  @spec chain_result_operations(String.t()) :: Result.t()
  def chain_result_operations(input) do
    step1 = EnhancedPatternMatchingTest.validateInput(input)
    temp_result = nil
    case (elem(step1, 0)) do
      0 ->
        _g = elem(step1, 1)
        validated = _g
        temp_result = EnhancedPatternMatchingTest.processData(validated)
      1 ->
        _g = elem(step1, 1)
        _g = elem(step1, 2)
        error = _g
        context = _g
        context = context
        if (context == nil), do: context = "", else: nil
        result = DataResult.Error(error, context)
        this = nil
        this = result
        temp_result = this
    end
    temp_result1 = nil
    case (elem(temp_result, 0)) do
      0 ->
        _g = elem(temp_result, 1)
        processed = _g
        temp_result1 = EnhancedPatternMatchingTest.formatOutput(processed)
      1 ->
        _g = elem(temp_result, 1)
        _g = elem(temp_result, 2)
        error = _g
        context = _g
        context = context
        if (context == nil), do: context = "", else: nil
        result = DataResult.Error(error, context)
        this = nil
        this = result
        temp_result1 = this
    end
    temp_result1
  end

  @doc """
    Test array patterns with length-based matching

  """
  @spec match_array_patterns(Array.t()) :: String.t()
  def match_array_patterns(arr) do
    temp_result = nil
    case (length(arr)) do
      0 ->
        temp_result = "empty array"
      1 ->
        _g = Enum.at(arr, 0)
        x = _g
        temp_result = "single element: " <> Integer.to_string(x)
      2 ->
        _g = Enum.at(arr, 0)
        _g = Enum.at(arr, 1)
        x = _g
        y = _g
        temp_result = "pair: [" <> Integer.to_string(x) <> ", " <> Integer.to_string(y) <> "]"
      3 ->
        _g = Enum.at(arr, 0)
        _g = Enum.at(arr, 1)
        _g = Enum.at(arr, 2)
        x = _g
        y = _g
        z = _g
        temp_result = "triple: [" <> Integer.to_string(x) <> ", " <> Integer.to_string(y) <> ", " <> Integer.to_string(z) <> "]"
      _ ->
        a = arr
        if (length(a) > 3), do: temp_result = "starts with " <> Integer.to_string(Enum.at(a, 0)) <> ", has " <> Integer.to_string((length(a) - 1)) <> " more elements", else: temp_result = "other array pattern"
    end
    temp_result
  end

  @doc """
    Test string patterns with complex conditions

  """
  @spec match_string_patterns(String.t()) :: String.t()
  def match_string_patterns(input) do
    temp_result = nil
    if (input == "") do
      temp_result = "empty string"
    else
      s = input
      if (String.length(s) == 1) do
        temp_result = "single character: \"" <> s <> "\""
      else
        s = input
        if (String.slice(s, 0, 7) == "prefix_") do
          temp_result = "has prefix: \"" <> s <> "\""
        else
          s = input
          if (String.slice(s, String.length(s) - 7..-1) == "_suffix") do
            temp_result = "has suffix: \"" <> s <> "\""
          else
            s = input
            if (case :binary.match(s, "@") do {pos, _} -> pos; :nomatch -> -1 end > -1) do
              temp_result = "contains @: \"" <> s <> "\""
            else
              s = input
              if (String.length(s) > 100) do
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

  @doc """
    Test tuple/object patterns with field matching

  """
  @spec match_object_patterns(term()) :: String.t()
  def match_object_patterns(data) do
    temp_result = nil
    _g = data.name
    _g = data.age
    _g = data.active
    case (_g) do
      false ->
        age = _g
        name = _g
        temp_result = "Inactive user: " <> name <> " (" <> Integer.to_string(age) <> ")"
      true ->
        age = _g
        name = _g
        if (age >= 18) do
          temp_result = "Active adult: " <> name <> " (" <> Integer.to_string(age) <> ")"
        else
          age = _g
          name = _g
          if (age < 18), do: temp_result = "Active minor: " <> name <> " (" <> Integer.to_string(age) <> ")", else: temp_result = "unknown pattern"
        end
      _ ->
        temp_result = "unknown pattern"
    end
    temp_result
  end

  @doc """
    Test enum patterns with validation state

  """
  @spec match_validation_state(ValidationState.t()) :: String.t()
  def match_validation_state(state) do
    temp_result = nil
    case (elem(state, 0)) do
      0 ->
        temp_result = "Data is valid"
      1 ->
        _g = elem(state, 1)
        errors = _g
        if (length(errors) == 1) do
          temp_result = "Single error: " <> Enum.at(errors, 0)
        else
          errors = _g
          if (length(errors) > 1) do
            temp_result = "Multiple errors: " <> Integer.to_string(length(errors)) <> " issues"
          else
            _g
            temp_result = "No specific errors"
          end
        end
      2 ->
        _g = elem(state, 1)
        validator = _g
        temp_result = "Validation pending by: " <> validator
    end
    temp_result
  end

  @doc """
    Test binary patterns for byte matching (if supported)

  """
  @spec match_binary_pattern(String.t()) :: String.t()
  def match_binary_pattern(data) do
    bytes = Bytes.ofString(data)
    temp_result = nil
    _g = length(bytes)
    case (_g) do
      0 ->
        temp_result = "empty"
      1 ->
        temp_result = "single byte: " <> Integer.to_string(Enum.at(bytes.b, 0))
      _ ->
        n = _g
        if (n <= 4) do
          temp_result = "small data: " <> Integer.to_string(n) <> " bytes"
        else
          n = _g
          temp_result = "large data: " <> Integer.to_string(n) <> " bytes"
        end
    end
    temp_result
  end

  @doc "Function validate_input"
  @spec validate_input(String.t()) :: Result.t()
  def validate_input(input) do
    if (String.length(input) == 0) do
      temp_result = nil
      context = "validation"
      if (context == nil), do: context = "", else: nil
      result = DataResult.Error("Empty input", context)
      this = nil
      this = result
      temp_result = this
      temp_result
    end
    if (String.length(input) > 1000) do
      temp_result1 = nil
      context = "validation"
      if (context == nil), do: context = "", else: nil
      result = DataResult.Error("Input too long", context)
      this = nil
      this = result
      temp_result1 = this
      temp_result1
    end
    temp_result2 = nil
    value = String.downcase(input)
    result = DataResult.Success(value)
    temp_result2 = result
    temp_result2
  end

  @doc "Function process_data"
  @spec process_data(String.t()) :: Result.t()
  def process_data(data) do
    if (case :binary.match(data, "error") do {pos, _} -> pos; :nomatch -> -1 end >= 0) do
      temp_result = nil
      context = "processing"
      if (context == nil), do: context = "", else: nil
      result = DataResult.Error("Data contains error keyword", context)
      this = nil
      this = result
      temp_result = this
      temp_result
    end
    temp_result1 = nil
    value = String.upcase(data)
    result = DataResult.Success(value)
    temp_result1 = result
    temp_result1
  end

  @doc "Function format_output"
  @spec format_output(String.t()) :: Result.t()
  def format_output(data) do
    if (String.length(data) == 0) do
      temp_result = nil
      context = "formatting"
      if (context == nil), do: context = "", else: nil
      result = DataResult.Error("No data to format", context)
      this = nil
      this = result
      temp_result = this
      temp_result
    end
    temp_result1 = nil
    result = DataResult.Success("Formatted: [" <> data <> "]")
    temp_result1 = result
    temp_result1
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("Enhanced pattern matching compilation test", %{"fileName" => "Main.hx", "lineNumber" => 231, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchStatus(Status.Working("compile")), %{"fileName" => "Main.hx", "lineNumber" => 234, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchStatus(Status.Completed("success", 1500)), %{"fileName" => "Main.hx", "lineNumber" => 235, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.incompleteMatch(Status.Failed("timeout", 2)), %{"fileName" => "Main.hx", "lineNumber" => 238, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    temp_result = nil
    temp_result1 = nil
    result = DataResult.Success("deep value")
    temp_result1 = result
    result = DataResult.Success(temp_result1)
    temp_result = result
    Log.trace(EnhancedPatternMatchingTest.matchNestedResult(temp_result), %{"fileName" => "Main.hx", "lineNumber" => 242, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchWithComplexGuards(Status.Working("urgent task"), 8, true), %{"fileName" => "Main.hx", "lineNumber" => 245, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchWithRangeGuards(85, "score"), %{"fileName" => "Main.hx", "lineNumber" => 248, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchWithRangeGuards(25, "temperature"), %{"fileName" => "Main.hx", "lineNumber" => 249, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.chainResultOperations("valid input"), %{"fileName" => "Main.hx", "lineNumber" => 252, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.chainResultOperations(""), %{"fileName" => "Main.hx", "lineNumber" => 253, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchArrayPatterns([1, 2, 3, 4, 5]), %{"fileName" => "Main.hx", "lineNumber" => 256, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchArrayPatterns([]), %{"fileName" => "Main.hx", "lineNumber" => 257, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchStringPatterns("prefix_test"), %{"fileName" => "Main.hx", "lineNumber" => 260, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchStringPatterns("test@example.com"), %{"fileName" => "Main.hx", "lineNumber" => 261, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchObjectPatterns(%{"name" => "Alice", "age" => 25, "active" => true}), %{"fileName" => "Main.hx", "lineNumber" => 264, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchObjectPatterns(%{"name" => "Bob", "age" => 16, "active" => true}), %{"fileName" => "Main.hx", "lineNumber" => 265, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchValidationState(ValidationState.Invalid(["Required field missing", "Invalid format"])), %{"fileName" => "Main.hx", "lineNumber" => 268, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchValidationState(ValidationState.Pending("security_validator")), %{"fileName" => "Main.hx", "lineNumber" => 269, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchBinaryPattern("test"), %{"fileName" => "Main.hx", "lineNumber" => 272, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
    Log.trace(EnhancedPatternMatchingTest.matchBinaryPattern(""), %{"fileName" => "Main.hx", "lineNumber" => 273, "className" => "EnhancedPatternMatchingTest", "methodName" => "main"})
  end

end


defmodule Status do
  @moduledoc """
  Status enum generated from Haxe
  
  
 * Enhanced Pattern Matching Test
 * Tests advanced pattern matching features including:
 * - Exhaustive checking with compile-time warnings
 * - Nested patterns with proper destructuring
 * - Complex guards with multiple conditions
 * - With statements for Result pattern handling
 * - Binary patterns for data processing
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :idle |
    {:working, term()} |
    {:completed, term(), term()} |
    {:failed, term(), term()}

  @doc "Creates idle enum value"
  @spec idle() :: :idle
  def idle(), do: :idle

  @doc """
  Creates working enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec working(term()) :: {:working, term()}
  def working(arg0) do
    {:working, arg0}
  end

  @doc """
  Creates completed enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec completed(term(), term()) :: {:completed, term(), term()}
  def completed(arg0, arg1) do
    {:completed, arg0, arg1}
  end

  @doc """
  Creates failed enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec failed(term(), term()) :: {:failed, term(), term()}
  def failed(arg0, arg1) do
    {:failed, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is idle variant"
  @spec is_idle(t()) :: boolean()
  def is_idle(:idle), do: true
  def is_idle(_), do: false

  @doc "Returns true if value is working variant"
  @spec is_working(t()) :: boolean()
  def is_working({:working, _}), do: true
  def is_working(_), do: false

  @doc "Returns true if value is completed variant"
  @spec is_completed(t()) :: boolean()
  def is_completed({:completed, _}), do: true
  def is_completed(_), do: false

  @doc "Returns true if value is failed variant"
  @spec is_failed(t()) :: boolean()
  def is_failed({:failed, _}), do: true
  def is_failed(_), do: false

  @doc "Extracts value from working variant, returns {:ok, value} or :error"
  @spec get_working_value(t()) :: {:ok, term()} | :error
  def get_working_value({:working, value}), do: {:ok, value}
  def get_working_value(_), do: :error

  @doc "Extracts value from completed variant, returns {:ok, value} or :error"
  @spec get_completed_value(t()) :: {:ok, {term(), term()}} | :error
  def get_completed_value({:completed, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_completed_value(_), do: :error

  @doc "Extracts value from failed variant, returns {:ok, value} or :error"
  @spec get_failed_value(t()) :: {:ok, {term(), term()}} | :error
  def get_failed_value({:failed, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_failed_value(_), do: :error

end


defmodule DataResult do
  @moduledoc """
  DataResult enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:success, term()} |
    {:error, term(), term()}

  @doc """
  Creates success enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec success(term()) :: {:success, term()}
  def success(arg0) do
    {:success, arg0}
  end

  @doc """
  Creates error enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec error(term(), term()) :: {:error, term(), term()}
  def error(arg0, arg1) do
    {:error, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is success variant"
  @spec is_success(t()) :: boolean()
  def is_success({:success, _}), do: true
  def is_success(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Extracts value from success variant, returns {:ok, value} or :error"
  @spec get_success_value(t()) :: {:ok, term()} | :error
  def get_success_value({:success, value}), do: {:ok, value}
  def get_success_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, {term(), term()}} | :error
  def get_error_value({:error, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_error_value(_), do: :error

end


defmodule ValidationState do
  @moduledoc """
  ValidationState enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :valid |
    {:invalid, term()} |
    {:pending, term()}

  @doc "Creates valid enum value"
  @spec valid() :: :valid
  def valid(), do: :valid

  @doc """
  Creates invalid enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec invalid(term()) :: {:invalid, term()}
  def invalid(arg0) do
    {:invalid, arg0}
  end

  @doc """
  Creates pending enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec pending(term()) :: {:pending, term()}
  def pending(arg0) do
    {:pending, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is valid variant"
  @spec is_valid(t()) :: boolean()
  def is_valid(:valid), do: true
  def is_valid(_), do: false

  @doc "Returns true if value is invalid variant"
  @spec is_invalid(t()) :: boolean()
  def is_invalid({:invalid, _}), do: true
  def is_invalid(_), do: false

  @doc "Returns true if value is pending variant"
  @spec is_pending(t()) :: boolean()
  def is_pending({:pending, _}), do: true
  def is_pending(_), do: false

  @doc "Extracts value from invalid variant, returns {:ok, value} or :error"
  @spec get_invalid_value(t()) :: {:ok, term()} | :error
  def get_invalid_value({:invalid, value}), do: {:ok, value}
  def get_invalid_value(_), do: :error

  @doc "Extracts value from pending variant, returns {:ok, value} or :error"
  @spec get_pending_value(t()) :: {:ok, term()} | :error
  def get_pending_value({:pending, value}), do: {:ok, value}
  def get_pending_value(_), do: :error

end
