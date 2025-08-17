defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test case for Universal Result<T,E> type compilation
     *
     * This test validates:
     * - Basic Result enum compilation
     * - Pattern matching on Result values
     * - ResultTools functional operations
     * - Type safety across success and error cases
     * - Proper Elixir tuple generation for {:ok, _} and {:error, _}
  """

  # Static functions
  @doc """
    Demonstrate basic Result usage with string operations

  """
  @spec parse_number(String.t()) :: Result.t()
  def parse_number(input) do
    parsed = Std.parseInt(input)
    if (parsed != nil), do: {:ok, parsed}, else: {:error, "Invalid number: " <> input}
  end

  @doc """
    Chain Result operations using flatMap

  """
  @spec divide_numbers(String.t(), String.t()) :: Result.t()
  def divide_numbers(a, b) do
    ResultTools.flatMap(Main.parseNumber(a), fn num_a -> ResultTools.flatMap(Main.parseNumber(b), fn num_b -> if (num_b == 0), do: {:error, "Division by zero"}, else: {:ok, num_a / num_b} end) end)
  end

  @doc """
    Transform Result values using map (with extension syntax)

  """
  @spec double_if_valid(String.t()) :: Result.t()
  def double_if_valid(input) do
    ResultTools.map(Main.parseNumber(input), fn num -> num * 2 end)
  end

  @doc """
    Handle Result using pattern matching

  """
  @spec handle_result(Result.t()) :: String.t()
  def handle_result(result) do
    temp_result = nil
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        value = _g
        temp_result = "Success: " <> Integer.to_string(value)
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        message = _g
        temp_result = "Error: " <> message
    end
    temp_result
  end

  @doc """
    Use fold to extract values safely

  """
  @spec get_value_or_default(Result.t()) :: integer()
  def get_value_or_default(result) do
    ResultTools.fold(result, fn value -> value end, fn error -> -1 end)
  end

  @doc """
    Demonstrate extension method chaining (similar to Option)

  """
  @spec test_extension_methods() :: nil
  def test_extension_methods() do
    result = {:ok, "hello"}
    ResultTools.map(result, fn s -> String.upcase(s) end)
    ResultTools.flatMap(result, fn s -> temp_result = nil
    if (String.length(s) > 0), do: temp_result = {:ok, s <> "!"}, else: temp_result = {:error, "empty"}
    temp_result end)
    ResultTools.isOk(result)
    ResultTools.isError(result)
    ResultTools.unwrapOr(result, "default")
  end

  @doc """
    Work with complex Result types (nested data)

  """
  @spec process_user(term()) :: Result.t()
  def process_user(user_data) do
    ResultTools.map(Main.parseNumber(user_data.age), fn parsed_age -> %{"name" => user_data.name, "age" => parsed_age} end)
  end

  @doc """
    Demonstrate Result utilities

  """
  @spec demonstrate_utilities() :: term()
  def demonstrate_utilities() do
    success = {:ok, 42}
    failure = {:error, "Something went wrong"}
    is_success_ok = ResultTools.isOk(success)
    is_failure_ok = ResultTools.isOk(failure)
    is_success_error = ResultTools.isError(success)
    is_failure_error = ResultTools.isError(failure)
    success_value = ResultTools.unwrapOr(success, 0)
    failure_value = ResultTools.unwrapOr(failure, 0)
    mapped_error = ResultTools.mapError(failure, fn err -> "Mapped: " <> err end)
    %{"isSuccessOk" => is_success_ok, "isFailureOk" => is_failure_ok, "isSuccessError" => is_success_error, "isFailureError" => is_failure_error, "successValue" => success_value, "failureValue" => failure_value, "mappedError" => mapped_error}
  end

  @doc """
    Demonstrate sequence operation for collecting Results

  """
  @spec process_multiple_numbers(Array.t()) :: Result.t()
  def process_multiple_numbers(inputs) do
    f = Main.parse_number
    _g = []
    _g = 0
    Enum.map(inputs, fn item -> v = Enum.at(inputs, _g)
    _g = _g + 1
    _g ++ [f(v)] end)
    ResultTools.sequence(_g)
  end

  @doc """
    Demonstrate traverse operation

  """
  @spec validate_and_double(Array.t()) :: Result.t()
  def validate_and_double(inputs) do
    ResultTools.traverse(inputs, fn input -> ResultTools.map(Main.parseNumber(input), fn num -> num * 2 end) end)
  end

  @doc """
    Main function demonstrating all Result patterns

  """
  @spec main() :: nil
  def main() do
    result1 = Main.parseNumber("123")
    result2 = Main.parseNumber("abc")
    div_result = Main.divideNumbers("10", "2")
    Main.divideNumbers("10", "0")
    doubled = Main.doubleIfValid("21")
    message1 = Main.handleResult(result1)
    message2 = Main.handleResult(result2)
    Main.getValueOrDefault(result1)
    Main.getValueOrDefault(result2)
    Main.processUser(%{"name" => "Alice", "age" => "25"})
    Main.demonstrateUtilities()
    numbers = Main.processMultipleNumbers(["1", "2", "3"])
    Main.processMultipleNumbers(["1", "x", "3"])
    Main.validateAndDouble(["5", "10", "15"])
    Log.trace("Parse \"123\": " <> message1, %{"fileName" => "Main.hx", "lineNumber" => 190, "className" => "Main", "methodName" => "main"})
    Log.trace("Parse \"abc\": " <> message2, %{"fileName" => "Main.hx", "lineNumber" => 191, "className" => "Main", "methodName" => "main"})
    Log.trace("Divide 10/2: " <> Std.string(div_result), %{"fileName" => "Main.hx", "lineNumber" => 192, "className" => "Main", "methodName" => "main"})
    Log.trace("Double 21: " <> Std.string(doubled), %{"fileName" => "Main.hx", "lineNumber" => 193, "className" => "Main", "methodName" => "main"})
    Log.trace("Numbers [1,2,3]: " <> Std.string(numbers), %{"fileName" => "Main.hx", "lineNumber" => 194, "className" => "Main", "methodName" => "main"})
    Log.trace("Utilities test completed", %{"fileName" => "Main.hx", "lineNumber" => 195, "className" => "Main", "methodName" => "main"})
  end

end
