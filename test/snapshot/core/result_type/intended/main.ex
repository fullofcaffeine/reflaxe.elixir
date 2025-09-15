defmodule Main do
  def parse_number(input) do
    parsed = Std.parse_int(input)

    if parsed != nil do
      {:ok, parsed}
    else
      {:error, "Invalid number: #{input}"}
    end
  end

  def divide_numbers(a, b) do
    ResultTools.flat_map(parse_number(a), fn num_a ->
      ResultTools.flat_map(parse_number(b), fn num_b ->
        if num_b == 0 do
          {:error, "Division by zero"}
        else
          {:ok, num_a / num_b}
        end
      end)
    end)
  end

  def double_if_valid(input) do
    ResultTools.map(parse_number(input), fn num -> num * 2 end)
  end

  def handle_result(result) do
    case result do
      {:ok, value} ->
        "Success: #{value}"
      {:error, message} ->
        "Error: #{message}"
    end
  end

  def get_value_or_default(result) do
    ResultTools.fold(result, fn value -> value end, fn _error -> -1 end)
  end

  def test_extension_methods() do
    result = {:ok, "hello"}
    _upper_result = ResultTools.map(result, fn s -> String.upcase(s) end)

    _chained_result = ResultTools.flat_map(result, fn s ->
      if String.length(s) > 0 do
        {:ok, "#{s}!"}
      else
        {:error, "empty"}
      end
    end)

    _is_valid = ResultTools.is_ok(result)
    _has_error = ResultTools.is_error(result)
    _value = ResultTools.unwrap_or(result, "default")
  end

  def process_user(user_data) do
    ResultTools.map(parse_number(user_data.age), fn parsed_age ->
      %{name: user_data.name, age: parsed_age}
    end)
  end

  def demonstrate_utilities() do
    success = {:ok, 42}
    failure = {:error, "Something went wrong"}

    is_success_ok = ResultTools.is_ok(success)
    is_failure_ok = ResultTools.is_ok(failure)
    is_success_error = ResultTools.is_error(success)
    is_failure_error = ResultTools.is_error(failure)

    success_value = ResultTools.unwrap_or(success, 0)
    failure_value = ResultTools.unwrap_or(failure, 0)

    mapped_error = ResultTools.map_error(failure, fn err -> "Mapped: #{err}" end)

    %{
      is_success_ok: is_success_ok,
      is_failure_ok: is_failure_ok,
      is_success_error: is_success_error,
      is_failure_error: is_failure_error,
      success_value: success_value,
      failure_value: failure_value,
      mapped_error: mapped_error
    }
  end

  def process_multiple_numbers(inputs) do
    results = Enum.map(inputs, &Main.parse_number/1)
    ResultTools.sequence(results)
  end

  def validate_and_double(inputs) do
    ResultTools.traverse(inputs, fn input ->
      ResultTools.map(parse_number(input), fn num -> num * 2 end)
    end)
  end

  def main() do
    result1 = parse_number("123")
    result2 = parse_number("abc")

    div_result = divide_numbers("10", "2")
    _div_error = divide_numbers("10", "0")

    doubled = double_if_valid("21")

    message1 = handle_result(result1)
    message2 = handle_result(result2)

    _value1 = get_value_or_default(result1)
    _value2 = get_value_or_default(result2)

    _user = process_user(%{name: "Alice", age: "25"})
    _utils = demonstrate_utilities()

    numbers = process_multiple_numbers(["1", "2", "3"])
    _numbers_error = process_multiple_numbers(["1", "x", "3"])
    _doubled_numbers = validate_and_double(["5", "10", "15"])

    Log.trace("Parse \"123\": #{message1}", %{:file_name => "Main.hx", :line_number => 190, :class_name => "Main", :method_name => "main"})
    Log.trace("Parse \"abc\": #{message2}", %{:file_name => "Main.hx", :line_number => 191, :class_name => "Main", :method_name => "main"})
    Log.trace("Divide 10/2: #{inspect(div_result)}", %{:file_name => "Main.hx", :line_number => 192, :class_name => "Main", :method_name => "main"})
    Log.trace("Double 21: #{inspect(doubled)}", %{:file_name => "Main.hx", :line_number => 193, :class_name => "Main", :method_name => "main"})
    Log.trace("Numbers [1,2,3]: #{inspect(numbers)}", %{:file_name => "Main.hx", :line_number => 194, :class_name => "Main", :method_name => "main"})
    Log.trace("Utilities test completed", %{:file_name => "Main.hx", :line_number => 195, :class_name => "Main", :method_name => "main"})
  end
end