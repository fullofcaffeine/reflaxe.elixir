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
  @doc "Generated from Haxe parseNumber"
  def parse_number(input) do
    parsed = Std.parse_int(input)

    if ((parsed != nil)) do
      {:ok, parsed}
    else
      {:error, "Invalid number: " <> input}
    end
  end

  @doc "Generated from Haxe divideNumbers"
  def divide_numbers(a, b) do
    ResultTools.flat_map(Main.parse_number(a), fn num_a -> ResultTools.flat_map(Main.parse_number(b), fn num_b -> if ((num_b == 0)) do
      {:error, "Division by zero"}
    else
      {:ok, (num_a / num_b)}
    end end) end)
  end

  @doc "Generated from Haxe doubleIfValid"
  def double_if_valid(input) do
    ResultTools.map(Main.parse_number(input), fn num -> (num * 2) end)
  end

  @doc "Generated from Haxe handleResult"
  def handle_result(result) do
    temp_result = nil

    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(result, 1)
    temp_result = "Success: " <> to_string(value)
      {1, message} -> g_array = elem(result, 1)
    temp_result = "Error: " <> message
    end

    temp_result
  end

  @doc "Generated from Haxe getValueOrDefault"
  def get_value_or_default(result) do
    ResultTools.fold(result, fn value -> value end, fn error -> -1 end)
  end

  @doc "Generated from Haxe testExtensionMethods"
  def test_extension_methods() do
    temp_result = nil

    result = {:ok, "hello"}

    _upper_result = ResultTools.map(result, fn s -> s.to_upper_case() end)

    _chained_result = ResultTools.flat_map(result, fn s -> if ((s.length > 0)), do: temp_result = {:ok, s <> "!"}, else: temp_result = {:error, "empty"}
    temp_result end)

    _is_valid = ResultTools.is_ok(result)

    _has_error = ResultTools.is_error(result)

    _value = ResultTools.unwrap_or(result, "default")
  end

  @doc "Generated from Haxe processUser"
  def process_user(user_data) do
    ResultTools.map(Main.parse_number(user_data.age), fn parsed_age -> %{"name" => user_data.name, "age" => parsed_age} end)
  end

  @doc "Generated from Haxe demonstrateUtilities"
  def demonstrate_utilities() do
    success = {:ok, 42}

    failure = {:error, "Something went wrong"}

    is_success_ok = ResultTools.is_ok(success)

    is_failure_ok = ResultTools.is_ok(failure)

    is_success_error = ResultTools.is_error(success)

    is_failure_error = ResultTools.is_error(failure)

    success_value = ResultTools.unwrap_or(success, 0)

    failure_value = ResultTools.unwrap_or(failure, 0)

    mapped_error = ResultTools.map_error(failure, fn err -> "Mapped: " <> err end)

    %{"isSuccessOk" => is_success_ok, "isFailureOk" => is_failure_ok, "isSuccessError" => is_success_error, "isFailureError" => is_failure_error, "successValue" => success_value, "failureValue" => failure_value, "mappedError" => mapped_error}
  end

  @doc "Generated from Haxe processMultipleNumbers"
  def process_multiple_numbers(inputs) do
    f = &Main.parse_number/1

    g_array = []

    g_counter = 0

    Enum.map(inputs, fn item -> f.(item) end)

    ResultTools.sequence(g_array)
  end

  @doc "Generated from Haxe validateAndDouble"
  def validate_and_double(inputs) do
    ResultTools.traverse(inputs, fn input -> ResultTools.map(Main.parse_number(input), fn num -> (num * 2) end) end)
  end

  @doc "Generated from Haxe main"
  def main() do
    result1 = Main.parse_number("123")

    result2 = Main.parse_number("abc")

    div_result = Main.divide_numbers("10", "2")

    _div_error = Main.divide_numbers("10", "0")

    doubled = Main.double_if_valid("21")

    message1 = Main.handle_result(result1)

    message2 = Main.handle_result(result2)

    _value1 = Main.get_value_or_default(result1)

    _value2 = Main.get_value_or_default(result2)

    _user = Main.process_user(%{"name" => "Alice", "age" => "25"})

    _utils = Main.demonstrate_utilities()

    numbers = Main.process_multiple_numbers(["1", "2", "3"])

    _numbers_error = Main.process_multiple_numbers(["1", "x", "3"])

    _doubled_numbers = Main.validate_and_double(["5", "10", "15"])

    Log.trace("Parse \"123\": " <> message1, %{"fileName" => "Main.hx", "lineNumber" => 190, "className" => "Main", "methodName" => "main"})

    Log.trace("Parse \"abc\": " <> message2, %{"fileName" => "Main.hx", "lineNumber" => 191, "className" => "Main", "methodName" => "main"})

    Log.trace("Divide 10/2: " <> Std.string(div_result), %{"fileName" => "Main.hx", "lineNumber" => 192, "className" => "Main", "methodName" => "main"})

    Log.trace("Double 21: " <> Std.string(doubled), %{"fileName" => "Main.hx", "lineNumber" => 193, "className" => "Main", "methodName" => "main"})

    Log.trace("Numbers [1,2,3]: " <> Std.string(numbers), %{"fileName" => "Main.hx", "lineNumber" => 194, "className" => "Main", "methodName" => "main"})

    Log.trace("Utilities test completed", %{"fileName" => "Main.hx", "lineNumber" => 195, "className" => "Main", "methodName" => "main"})
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
