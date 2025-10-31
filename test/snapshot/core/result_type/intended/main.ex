defmodule Main do
  def parse_number(input) do
    parsed = String.to_integer(input)
    if (not Kernel.is_nil(parsed)), do: {:some, {:ok, parsed}}, else: {:some, {:error, "Invalid number: " <> input}}
  end
  def divide_numbers(a, b) do
    MyApp.ResultTools.flat_map(parse_number(a), fn num_a ->
      ResultTools.flat_map(parse_number(b), fn num_b ->
        if (num_b == 0), do: {:error, "Division by zero"}, else: {:ok, num_a / num_b}
      end)
    end)
  end
  def double_if_valid(input) do
    MyApp.ResultTools.map(parse_number(input), fn num -> num * 2 end)
  end
  def handle_result(result) do
    (case result do
      {:ok, value} ->
        end_ = value
        fn_ = value
        end_ = value
        fn_ = value
        "Success: #{(fn -> value end).()}"
      {:error, message} ->
        end_ = message
        fn_ = message
        "Error: #{(fn -> message end).()}"
    end)
  end
  def get_value_or_default(result) do
    MyApp.ResultTools.fold(result, fn value -> value end, fn _error -> -1 end)
  end
  def test_extension_methods() do
    result = "hello"
    _ = MyApp.ResultTools.map(result, fn s -> String.upcase(s) end)
    _ = MyApp.ResultTools.flat_map(result, fn s ->
      if (length(s) > 0), do: s <> "!", else: "empty"
    end)
    _ = MyApp.ResultTools.is_ok(result)
    _ = MyApp.ResultTools.is_error(result)
    _ = MyApp.ResultTools.unwrap_or(result, "default")
  end
  def process_user(user_data) do
    MyApp.ResultTools.map(parse_number(user_data.age), fn parsed_age -> %{:name => user_data.name, :age => parsed_age} end)
  end
  def demonstrate_utilities() do
    success = 42
    failure = "Something went wrong"
    is_success_ok = MyApp.ResultTools.is_ok(success)
    is_failure_ok = MyApp.ResultTools.is_ok(failure)
    is_success_error = MyApp.ResultTools.is_error(success)
    is_failure_error = MyApp.ResultTools.is_error(failure)
    success_value = MyApp.ResultTools.unwrap_or(success, 0)
    failure_value = MyApp.ResultTools.unwrap_or(failure, 0)
    mapped_error = MyApp.ResultTools.map_error(failure, fn err -> "Mapped: " <> err end)
    %{:is_success_ok => is_success_ok, :is_failure_ok => is_failure_ok, :is_success_error => is_success_error, :is_failure_error => is_failure_error, :success_value => success_value, :failure_value => failure_value, :mapped_error => mapped_error}
  end
  def process_multiple_numbers(inputs) do
    results = Enum.map(inputs, :"main.parse_number")
    MyApp.ResultTools.sequence(results)
  end
  def validate_and_double(inputs) do
    MyApp.ResultTools.traverse(inputs, fn input -> ResultTools.map(parse_number(input), fn num -> num * 2 end) end)
  end
  def main() do
    result1 = parse_number("123")
    result2 = parse_number("abc")
    div_result = divide_numbers("10", "2")
    _ = divide_numbers("10", "0")
    doubled = double_if_valid("21")
    message1 = handle_result(result1)
    message2 = handle_result(result2)
    _ = get_value_or_default(result1)
    _ = get_value_or_default(result2)
    _ = process_user(%{:name => "Alice", :age => "25"})
    _ = demonstrate_utilities()
    numbers = process_multiple_numbers(["1", "2", "3"])
    _ = process_multiple_numbers(["1", "x", "3"])
    _ = validate_and_double(["5", "10", "15"])
    Log.trace("Parse \"123\": #{(fn -> message1 end).()}", %{:file_name => "Main.hx", :line_number => 191, :class_name => "Main", :method_name => "main"})
    Log.trace("Parse \"abc\": #{(fn -> message2 end).()}", %{:file_name => "Main.hx", :line_number => 192, :class_name => "Main", :method_name => "main"})
    Log.trace("Divide 10/2: #{(fn -> inspect(div_result) end).()}", %{:file_name => "Main.hx", :line_number => 193, :class_name => "Main", :method_name => "main"})
    Log.trace("Double 21: #{(fn -> inspect(doubled) end).()}", %{:file_name => "Main.hx", :line_number => 194, :class_name => "Main", :method_name => "main"})
    Log.trace("Numbers [1,2,3]: #{(fn -> inspect(numbers) end).()}", %{:file_name => "Main.hx", :line_number => 195, :class_name => "Main", :method_name => "main"})
    Log.trace("Utilities test completed", %{:file_name => "Main.hx", :line_number => 196, :class_name => "Main", :method_name => "main"})
  end
end
