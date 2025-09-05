defmodule Main do
  def parse_number(input) do
    parsed = Std.parse_int(input)
    if (parsed != nil), do: {:Ok, parsed}, else: {:Error, "Invalid number: " <> input}
  end
  def divide_numbers(a, b) do
    {:FlatMap, {:ParseNumber, a}, fn _num_a -> {:FlatMap, {:ParseNumber, b}, fn num_b -> if (num_b == 0), do: {:Error, "Division by zero"}, else: {:Ok, _num_a / num_b} end} end}
  end
  def double_if_valid(input) do
    {:Map, {:ParseNumber, input}, fn num -> num * 2 end}
  end
  def handle_result(result) do
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        value = g
        "Success: " <> value
      1 ->
        g = elem(result, 1)
        message = g
        "Error: " <> message
    end
  end
  def get_value_or_default(result) do
    ResultTools.fold(result, fn value -> value end, fn _error -> -1 end)
  end
  def test_extension_methods() do
    result = {:Ok, "hello"}
    _upper_result = {:Map, result, fn s -> s.toUpperCase() end}
    chained_result = {:FlatMap, result, fn s -> if (s.length > 0), do: {:Ok, s <> "!"}, else: {:Error, "empty"} end}
    is_valid = ResultTools.is_ok(result)
    has_error = ResultTools.is_error(result)
    value = ResultTools.unwrap_or(result, "default")
  end
  def process_user(user_data) do
    {:Map, {:ParseNumber, user_data.age}, fn parsed_age -> %{:name => user_data.name, :age => parsed_age} end}
  end
  def demonstrate_utilities() do
    success = {:Ok, 42}
    failure = {:Error, "Something went wrong"}
    is_success_ok = ResultTools.is_ok(success)
    is_failure_ok = ResultTools.is_ok(failure)
    is_success_error = ResultTools.is_error(success)
    is_failure_error = ResultTools.is_error(failure)
    success_value = ResultTools.unwrap_or(success, 0)
    failure_value = ResultTools.unwrap_or(failure, 0)
    mapped_error = {:MapError, failure, fn err -> "Mapped: " <> err end}
    %{:isSuccessOk => is_success_ok, :isFailureOk => is_failure_ok, :isSuccessError => is_success_error, :isFailureError => is_failure_error, :successValue => success_value, :failureValue => failure_value, :mappedError => mapped_error}
  end
  def process_multiple_numbers(inputs) do
    results = Enum.map(inputs, Main.parseNumber)
    {:Sequence, results}
  end
  def validate_and_double(inputs) do
    {:Traverse, inputs, fn input -> {:Map, {:ParseNumber, input}, fn num -> num * 2 end} end}
  end
  def main() do
    result1 = {:ParseNumber, "123"}
    result2 = {:ParseNumber, "abc"}
    div_result = {:DivideNumbers, "10", "2"}
    _div_error = {:DivideNumbers, "10", "0"}
    doubled = {:DoubleIfValid, "21"}
    message1 = handle_result(result1)
    message2 = handle_result(result2)
    _value1 = get_value_or_default(result1)
    _value2 = get_value_or_default(result2)
    _user = {:ProcessUser, %{:name => "Alice", :age => "25"}}
    _utils = demonstrate_utilities()
    numbers = {:ProcessMultipleNumbers, ["1", "2", "3"]}
    _numbers_error = {:ProcessMultipleNumbers, ["1", "x", "3"]}
    _doubled_numbers = {:ValidateAndDouble, ["5", "10", "15"]}
    Log.trace("Parse \"123\": " <> message1, %{:fileName => "Main.hx", :lineNumber => 190, :className => "Main", :methodName => "main"})
    Log.trace("Parse \"abc\": " <> message2, %{:fileName => "Main.hx", :lineNumber => 191, :className => "Main", :methodName => "main"})
    Log.trace("Divide 10/2: " <> Std.string(div_result), %{:fileName => "Main.hx", :lineNumber => 192, :className => "Main", :methodName => "main"})
    Log.trace("Double 21: " <> Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 193, :className => "Main", :methodName => "main"})
    Log.trace("Numbers [1,2,3]: " <> Std.string(numbers), %{:fileName => "Main.hx", :lineNumber => 194, :className => "Main", :methodName => "main"})
    Log.trace("Utilities test completed", %{:fileName => "Main.hx", :lineNumber => 195, :className => "Main", :methodName => "main"})
  end
end