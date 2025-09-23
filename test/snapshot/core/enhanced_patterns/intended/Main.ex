defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc """
    Test binary pattern matching: <<data::binary>>
    Addresses binary pattern issues from troubleshooting guide
  """
  @spec test_binary_patterns() :: String.t()
  def test_binary_patterns() do
    data = [72, 101, 108, 108, 111]  # "Hello" in bytes

    case data do
      [] ->
        "Empty binary"
      [72] ->
        "Starts with 'H' (single byte)"
      [72 | rest] when length(rest) > 0 ->
        rest_str = Enum.map(rest, &to_string/1) |> Enum.join(",")
        "Starts with 'H', rest: #{rest_str}"
      [72, _, _, _, _] ->
        "5-byte message starting with H"
      [first, second] when first > 64 and first < 90 ->
        "2-byte uppercase start"
      bytes when length(bytes) > 10 ->
        "Large binary: #{length(bytes)} bytes"
      _ ->
        "Other binary pattern"
    end
  end

  @doc """
    Test complex binary segment patterns
    Tests enhanced binary compilation features
  """
  @spec test_complex_binary_segments() :: String.t()
  def test_complex_binary_segments() do
    packet = [1, 0, 8, 72, 101, 108, 108, 111]

    case packet do
      [1, 0, size] ->
        "Protocol v1, size=#{size} (header only)"
      [1, 0, size | rest] when length(rest) > 0 ->
        data_str = Enum.map(rest, &to_string/1) |> Enum.join(",")
        "Protocol v1, size=#{size}, data=#{data_str}"
      [version, _flags, _size] when version > 1 ->
        "Future protocol v#{version}"
      [version, flags, size, _payload] ->
        "Packet: v#{version}, flags=#{flags}, size=#{size}"
      header when length(header) < 3 ->
        "Incomplete header"
      _ ->
        "Unknown packet format"
    end
  end

  @doc """
    Test pin operator patterns: ^existing_var
    Addresses pin operator issues from troubleshooting guide
  """
  @spec test_pin_operator_patterns() :: String.t()
  def test_pin_operator_patterns() do
    expected_value = 42
    expected_name = "test"
    test_value = 42
    test_name = "test"

    # Test basic pin patterns
    result1 = case test_value do
      value when value == expected_value -> "Matches expected value"
      _ -> "Different value"
    end

    # Test pin with complex expressions
    result2 = case {test_value, test_name} do
      {v, n} when v == expected_value and n == expected_name -> "Both match"
      {v, _n} when v == expected_value -> "Value matches, name different"
      {_v, n} when n == expected_name -> "Name matches, value different"
      _ -> "Neither matches"
    end

    "#{result1} | #{result2}"
  end

  @doc """
    Test advanced guard expressions: when conditions
    Addresses guard expression issues from troubleshooting guide
  """
  @spec test_advanced_guards() :: String.t()
  def test_advanced_guards() do
    temperature = 23.5
    humidity = 65
    pressure = 1013.25

    case {temperature, humidity, pressure} do
      {t, h, _p} when t > 20 and t < 25 and h >= 60 and h <= 70 ->
        "Perfect conditions"
      {t, h, _p} when t > 30 or h > 80 ->
        "Too hot or humid"
      {t, h, _p} when t < 10 or h < 30 ->
        "Too cold or dry"
      {_t, _h, p} when p < 1000 or p > 1020 ->
        "Abnormal pressure"
      {t, h, p} when t >= 15 and t <= 25 and h >= 40 and h <= 75 and p >= 1000 and p <= 1020 ->
        "Acceptable conditions"
      _ ->
        "Unknown conditions"
    end
  end

  @doc """
    Test type guards with Elixir-style functions
    Tests guard compilation enhancements
  """
  @spec test_type_guards() :: String.t()
  def test_type_guards() do
    value = "Hello World"

    cond do
      is_binary(value) and byte_size(value) > 10 ->
        "Long string: #{value}"
      is_binary(value) and byte_size(value) <= 10 ->
        "Short string: #{value}"
      is_integer(value) and value > 0 ->
        "Positive integer: #{value}"
      is_integer(value) and value <= 0 ->
        "Non-positive integer: #{value}"
      is_float(value) ->
        "Float value: #{value}"
      is_boolean(value) ->
        "Boolean value: #{value}"
      is_list(value) ->
        "Array with #{length(value)} elements"
      value == nil ->
        "Null value"
      true ->
        "Unknown type"
    end
  end

  @doc """
    Test range guard expressions
    Tests enhanced guard capabilities
  """
  @spec test_range_guards() :: String.t()
  def test_range_guards() do
    score = 85

    cond do
      score >= 90 and score <= 100 -> "Grade A (90-100)"
      score >= 80 and score < 90 -> "Grade B (80-89)"
      score >= 70 and score < 80 -> "Grade C (70-79)"
      score >= 60 and score < 70 -> "Grade D (60-69)"
      score >= 0 and score < 60 -> "Grade F (0-59)"
      score < 0 or score > 100 -> "Invalid score"
      true -> "Unknown score"
    end
  end

  @doc """
    Test exhaustive pattern validation
    Addresses exhaustive pattern checking from troubleshooting guide
  """
  @spec test_exhaustive_patterns() :: String.t()
  def test_exhaustive_patterns() do
    # Test boolean exhaustiveness
    flag = true
    bool_result = case flag do
      true -> "True case"
      false -> "False case"
    end

    # Test enum-like exhaustiveness with constants
    status = 1
    enum_result = case status do
      0 -> "Inactive"
      1 -> "Active"
      2 -> "Pending"
      3 -> "Error"
      _ -> "Unknown status"
    end

    # Test array length exhaustiveness
    items = [1, 2, 3]
    array_result = case items do
      [] -> "Empty"
      [x] -> "Single: #{x}"
      [x, y] -> "Pair: #{x},#{y}"
      [x, y, z] -> "Triple: #{x},#{y},#{z}"
      arr when length(arr) > 3 -> "Many: #{length(arr)} items"
      _ -> "Other array pattern"
    end

    "#{bool_result} | #{enum_result} | #{array_result}"
  end

  @doc """
    Test nested patterns with guards
    Tests complex pattern matching scenarios
  """
  @spec test_nested_patterns_with_guards() :: String.t()
  def test_nested_patterns_with_guards() do
    data = %{
      user: %{
        name: "Alice",
        age: 28,
        active: true
      },
      permissions: ["read", "write"],
      last_login: 1640995200
    }

    age = data.user.age
    perms = length(data.permissions)
    active = data.user.active

    cond do
      age >= 18 and age < 25 and perms > 0 and active ->
        "Young adult with permissions"
      age >= 25 and age < 65 and perms >= 2 and active ->
        "Adult with full permissions"
      age >= 65 and active ->
        "Senior user"
      not active ->
        "Inactive user"
      perms == 0 ->
        "User without permissions"
      true ->
        "Other user type"
    end
  end

  @doc """
    Test performance with complex guard combinations
    Ensures guard compilation is efficient
  """
  @spec test_complex_guard_performance() :: String.t()
  def test_complex_guard_performance() do
    metrics = %{
      cpu: 45.2,
      memory: 68.7,
      disk: 23.1,
      network: 12.8
    }

    cpu = metrics.cpu
    mem = metrics.memory
    disk = metrics.disk
    net = metrics.network

    cond do
      cpu > 80 or mem > 90 or disk > 90 or net > 80 ->
        "Critical resource usage"
      cpu > 60 or mem > 75 or disk > 75 or net > 60 ->
        "High resource usage"
      cpu > 40 and mem > 50 and disk > 50 and net > 30 ->
        "Moderate resource usage"
      cpu <= 40 and mem <= 50 and disk <= 50 and net <= 30 ->
        "Low resource usage"
      true ->
        "Unknown resource state"
    end
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("Enhanced Pattern Matching Test Suite", %{:file_name => "Main.hx", :line_number => 260, :class_name => "Main", :method_name => "main"})
    Log.trace("Binary Patterns: #{test_binary_patterns()}", %{:file_name => "Main.hx", :line_number => 263, :class_name => "Main", :method_name => "main"})
    Log.trace("Complex Binary: #{test_complex_binary_segments()}", %{:file_name => "Main.hx", :line_number => 264, :class_name => "Main", :method_name => "main"})
    Log.trace("Pin Operators: #{test_pin_operator_patterns()}", %{:file_name => "Main.hx", :line_number => 265, :class_name => "Main", :method_name => "main"})
    Log.trace("Advanced Guards: #{test_advanced_guards()}", %{:file_name => "Main.hx", :line_number => 266, :class_name => "Main", :method_name => "main"})
    Log.trace("Type Guards: #{test_type_guards()}", %{:file_name => "Main.hx", :line_number => 267, :class_name => "Main", :method_name => "main"})
    Log.trace("Range Guards: #{test_range_guards()}", %{:file_name => "Main.hx", :line_number => 268, :class_name => "Main", :method_name => "main"})
    Log.trace("Exhaustive Patterns: #{test_exhaustive_patterns()}", %{:file_name => "Main.hx", :line_number => 269, :class_name => "Main", :method_name => "main"})
    Log.trace("Nested Guards: #{test_nested_patterns_with_guards()}", %{:file_name => "Main.hx", :line_number => 270, :class_name => "Main", :method_name => "main"})
    Log.trace("Performance Guards: #{test_complex_guard_performance()}", %{:file_name => "Main.hx", :line_number => 271, :class_name => "Main", :method_name => "main"})
  end
end
