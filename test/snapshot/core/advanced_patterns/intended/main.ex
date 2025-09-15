defmodule Main do
  def match_simple_value(value) do
    case value do
      0 ->
        "zero"
      1 ->
        "one"
      2 ->
        "two"
      n when n < 0 ->
        "negative"
      n when n > 100 ->
        "large"
      _ ->
        "other"
    end
  end

  def process_array(arr) do
    case arr do
      [] ->
        "empty"
      [x] ->
        "single: #{x}"
      [x, y] ->
        "pair: #{x},#{y}"
      [x, y, z] ->
        "triple: #{x},#{y},#{z}"
      [first, second, third, fourth] ->
        "quad: #{first},#{second},#{third},#{fourth}"
      _ ->
        "many: #{length(arr)} items"
    end
  end

  def match_tuple(data) do
    case data do
      {:ok, value} ->
        "success: #{value}"
      {:error, reason} ->
        "error: #{reason}"
      {:warning, msg} ->
        "warning: #{msg}"
      _ ->
        "unknown"
    end
  end

  def nested_pattern(data) do
    case data do
      {:ok, {:data, value}} ->
        "nested data: #{value}"
      {:ok, {:error, reason}} ->
        "nested error: #{reason}"
      {:error, {:timeout, ms}} ->
        "timeout after #{ms}ms"
      _ ->
        "other nested"
    end
  end

  def match_with_guards(x, y) do
    case {x, y} do
      {a, b} when a > 0 and b > 0 ->
        "both positive"
      {a, b} when a < 0 and b < 0 ->
        "both negative"
      {0, _} ->
        "x is zero"
      {_, 0} ->
        "y is zero"
      {a, b} when a * b < 0 ->
        "opposite signs"
      _ ->
        "other"
    end
  end

  def complex_guard(value) do
    case value do
      n when is_integer(n) and n > 0 and rem(n, 2) == 0 ->
        "positive even"
      n when is_integer(n) and n > 0 and rem(n, 2) == 1 ->
        "positive odd"
      n when is_integer(n) and n < 0 ->
        "negative integer"
      0 ->
        "zero"
      f when is_float(f) ->
        "float: #{f}"
      s when is_binary(s) ->
        "string: #{s}"
      _ ->
        "other type"
    end
  end

  def main() do
    Log.trace(match_simple_value(0), %{:file_name => "Main.hx", :line_number => 75, :class_name => "Main", :method_name => "main"})
    Log.trace(match_simple_value(1), %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "main"})
    Log.trace(match_simple_value(-5), %{:file_name => "Main.hx", :line_number => 77, :class_name => "Main", :method_name => "main"})
    Log.trace(match_simple_value(150), %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "main"})
    Log.trace(match_simple_value(50), %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "main"})

    Log.trace(process_array([]), %{:file_name => "Main.hx", :line_number => 82, :class_name => "Main", :method_name => "main"})
    Log.trace(process_array([10]), %{:file_name => "Main.hx", :line_number => 83, :class_name => "Main", :method_name => "main"})
    Log.trace(process_array([10, 20]), %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "main"})
    Log.trace(process_array([10, 20, 30]), %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "main"})
    Log.trace(process_array([1, 2, 3, 4]), %{:file_name => "Main.hx", :line_number => 86, :class_name => "Main", :method_name => "main"})
    Log.trace(process_array([1, 2, 3, 4, 5, 6]), %{:file_name => "Main.hx", :line_number => 87, :class_name => "Main", :method_name => "main"})

    Log.trace(match_tuple({:ok, "data"}), %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "main"})
    Log.trace(match_tuple({:error, "not found"}), %{:file_name => "Main.hx", :line_number => 91, :class_name => "Main", :method_name => "main"})
    Log.trace(match_tuple({:warning, "deprecated"}), %{:file_name => "Main.hx", :line_number => 92, :class_name => "Main", :method_name => "main"})
    Log.trace(match_tuple({:other, "value"}), %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "main"})

    Log.trace(nested_pattern({:ok, {:data, "value"}}), %{:file_name => "Main.hx", :line_number => 96, :class_name => "Main", :method_name => "main"})
    Log.trace(nested_pattern({:ok, {:error, "failed"}}), %{:file_name => "Main.hx", :line_number => 97, :class_name => "Main", :method_name => "main"})
    Log.trace(nested_pattern({:error, {:timeout, 5000}}), %{:file_name => "Main.hx", :line_number => 98, :class_name => "Main", :method_name => "main"})

    Log.trace(match_with_guards(5, 3), %{:file_name => "Main.hx", :line_number => 101, :class_name => "Main", :method_name => "main"})
    Log.trace(match_with_guards(-2, -8), %{:file_name => "Main.hx", :line_number => 102, :class_name => "Main", :method_name => "main"})
    Log.trace(match_with_guards(0, 5), %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "main"})
    Log.trace(match_with_guards(3, 0), %{:file_name => "Main.hx", :line_number => 104, :class_name => "Main", :method_name => "main"})
    Log.trace(match_with_guards(3, -5), %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "main"})

    Log.trace(complex_guard(4), %{:file_name => "Main.hx", :line_number => 108, :class_name => "Main", :method_name => "main"})
    Log.trace(complex_guard(3), %{:file_name => "Main.hx", :line_number => 109, :class_name => "Main", :method_name => "main"})
    Log.trace(complex_guard(-5), %{:file_name => "Main.hx", :line_number => 110, :class_name => "Main", :method_name => "main"})
    Log.trace(complex_guard(0), %{:file_name => "Main.hx", :line_number => 111, :class_name => "Main", :method_name => "main"})
    Log.trace(complex_guard(3.14), %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "main"})
    Log.trace(complex_guard("hello"), %{:file_name => "Main.hx", :line_number => 113, :class_name => "Main", :method_name => "main"})
  end
end