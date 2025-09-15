defmodule EnhancedPatternMatchingTest do
  def match_status(status) do
    case status do
      {:idle} ->
        "Currently idle"
      {:working, task} ->
        "Working on: #{task}"
      {:completed, result, duration} ->
        "Completed \"#{result}\" in #{duration}ms"
      {:failed, error, retries} ->
        "Failed with \"#{error}\" after #{retries} retries"
    end
  end

  def incomplete_match(status) do
    case status do
      {:idle} ->
        "idle"
      {:working, task} ->
        "working: #{task}"
      _ ->
        "unknown"
    end
  end

  def match_nested_result(result) do
    case result do
      {:ok, inner_result} ->
        case inner_result do
          {:success, value} ->
            "Double success: #{value}"
          {:error, inner_error, inner_context} ->
            "Outer success, inner error: #{inner_error} (context: #{inner_context})"
        end
      {:error, outer_error, outer_context} ->
        "Outer error: #{outer_error} (context: #{outer_context})"
    end
  end

  def match_with_complex_guards(status, priority, is_urgent) do
    case status do
      {:idle} ->
        "idle"
      {:working, task} when priority > 5 and is_urgent ->
        "High priority urgent task: #{task}"
      {:working, task} when priority > 3 and not is_urgent ->
        "High priority normal task: #{task}"
      {:working, task} when priority <= 3 and is_urgent ->
        "Low priority urgent task: #{task}"
      {:working, task} ->
        "Normal task: #{task}"
      {:completed, result, duration} when duration < 1000 ->
        "Fast completion: #{result}"
      {:completed, result, duration} when duration >= 1000 and duration < 5000 ->
        "Normal completion: #{result}"
      {:completed, result, _duration} ->
        "Slow completion: #{result}"
      {:failed, error, retries} when retries < 3 ->
        "Recoverable failure: #{error}"
      {:failed, error, _retries} ->
        "Permanent failure: #{error}"
    end
  end

  def match_with_range_guards(value, category) do
    case category do
      "score" ->
        cond do
          value >= 90 -> "Excellent score"
          value >= 70 -> "Good score"
          value >= 50 -> "Average score"
          value < 50 -> "Poor score"
          true -> "Unknown score value: #{value}"
        end
      "temperature" ->
        cond do
          value >= 30 -> "Hot"
          value >= 20 -> "Warm"
          value >= 10 -> "Cool"
          value < 10 -> "Cold"
          true -> "Unknown temperature: #{value}"
        end
      "age" ->
        cond do
          value >= 60 -> "Senior"
          value >= 30 -> "Adult"
          value >= 18 -> "Young adult"
          value < 18 -> "Minor"
          true -> "Unknown age: #{value}"
        end
      other ->
        "Unknown category \"#{other}\" with value #{value}"
    end
  end

  def match_tuple_patterns(data) do
    case data do
      {x, y} when is_integer(x) and is_integer(y) ->
        "Point at (#{x}, #{y})"
      {name, age} when is_binary(name) and is_integer(age) ->
        "Person: #{name}, age #{age}"
      {a, b, c} when is_number(a) and is_number(b) and is_number(c) ->
        "Triangle with sides: #{a}, #{b}, #{c}"
      {status, message} when is_atom(status) ->
        "Status #{status}: #{message}"
      _ ->
        "Unknown tuple pattern"
    end
  end

  def match_list_patterns(list) do
    case list do
      [] ->
        "Empty list"
      [x] ->
        "Single element: #{x}"
      [x, y] ->
        "Pair: #{x} and #{y}"
      [h | t] when length(t) > 0 ->
        "List with head #{h} and #{length(t)} more elements"
      _ ->
        "Unknown list pattern"
    end
  end

  def match_validation_state(state) do
    case state do
      {:valid, data} ->
        "Valid: #{inspect(data)}"
      {:invalid, errors} when is_list(errors) ->
        "Invalid with #{length(errors)} errors"
      {:invalid, error} when is_binary(error) ->
        "Invalid: #{error}"
      {:pending} ->
        "Validation pending"
      {:unknown} ->
        "Unknown validation state"
      _ ->
        "Unexpected state"
    end
  end

  def match_recursive_structure(tree) do
    case tree do
      {:leaf, value} ->
        "Leaf: #{value}"
      {:node, left, right} ->
        left_desc = match_recursive_structure(left)
        right_desc = match_recursive_structure(right)
        "Node(#{left_desc}, #{right_desc})"
      nil ->
        "Empty"
      _ ->
        "Unknown tree structure"
    end
  end

  def pattern_with_type_test(value) do
    cond do
      is_integer(value) -> "Integer: #{value}"
      is_float(value) -> "Float: #{value}"
      is_binary(value) -> "String: #{value}"
      is_boolean(value) -> "Boolean: #{value}"
      is_atom(value) -> "Atom: #{value}"
      is_list(value) -> "List with #{length(value)} elements"
      is_map(value) -> "Map with #{map_size(value)} keys"
      true -> "Unknown type"
    end
  end

  def test_all_patterns() do
    Log.trace("Testing Status patterns:", %{:file_name => "Main.hx", :line_number => 286, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_status({:idle}), %{:file_name => "Main.hx", :line_number => 287, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_status({:working, "important task"}), %{:file_name => "Main.hx", :line_number => 288, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_status({:completed, "data processing", 1250}), %{:file_name => "Main.hx", :line_number => 289, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_status({:failed, "network error", 3}), %{:file_name => "Main.hx", :line_number => 290, :class_name => "Main", :method_name => "testAllPatterns"})

    Log.trace("\nTesting incomplete match:", %{:file_name => "Main.hx", :line_number => 292, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(incomplete_match({:idle}), %{:file_name => "Main.hx", :line_number => 293, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(incomplete_match({:working, "task"}), %{:file_name => "Main.hx", :line_number => 294, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(incomplete_match({:completed, "done", 100}), %{:file_name => "Main.hx", :line_number => 295, :class_name => "Main", :method_name => "testAllPatterns"})

    Log.trace("\nTesting nested results:", %{:file_name => "Main.hx", :line_number => 297, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_nested_result({:ok, {:success, 42}}), %{:file_name => "Main.hx", :line_number => 298, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_nested_result({:ok, {:error, "parse error", "line 10"}}), %{:file_name => "Main.hx", :line_number => 299, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_nested_result({:error, "connection failed", "timeout"}) , %{:file_name => "Main.hx", :line_number => 300, :class_name => "Main", :method_name => "testAllPatterns"})

    Log.trace("\nTesting complex guards:", %{:file_name => "Main.hx", :line_number => 302, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_with_complex_guards({:working, "critical task"}, 10, true), %{:file_name => "Main.hx", :line_number => 303, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_with_complex_guards({:working, "normal task"}, 4, false), %{:file_name => "Main.hx", :line_number => 304, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_with_complex_guards({:completed, "report", 500}, 0, false), %{:file_name => "Main.hx", :line_number => 305, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_with_complex_guards({:failed, "disk full", 5}, 0, false), %{:file_name => "Main.hx", :line_number => 306, :class_name => "Main", :method_name => "testAllPatterns"})

    Log.trace("\nTesting range guards:", %{:file_name => "Main.hx", :line_number => 308, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_with_range_guards(95, "score"), %{:file_name => "Main.hx", :line_number => 309, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_with_range_guards(65, "score"), %{:file_name => "Main.hx", :line_number => 310, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_with_range_guards(25, "temperature"), %{:file_name => "Main.hx", :line_number => 311, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_with_range_guards(5, "temperature"), %{:file_name => "Main.hx", :line_number => 312, :class_name => "Main", :method_name => "testAllPatterns"})

    Log.trace("\nTesting tuple patterns:", %{:file_name => "Main.hx", :line_number => 314, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_tuple_patterns({10, 20}), %{:file_name => "Main.hx", :line_number => 315, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_tuple_patterns({"Alice", 25}), %{:file_name => "Main.hx", :line_number => 316, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_tuple_patterns({3.0, 4.0, 5.0}), %{:file_name => "Main.hx", :line_number => 317, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_tuple_patterns({:ok, "Success"}), %{:file_name => "Main.hx", :line_number => 318, :class_name => "Main", :method_name => "testAllPatterns"})

    Log.trace("\nTesting list patterns:", %{:file_name => "Main.hx", :line_number => 320, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_list_patterns([]), %{:file_name => "Main.hx", :line_number => 321, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_list_patterns([42]), %{:file_name => "Main.hx", :line_number => 322, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_list_patterns([1, 2]), %{:file_name => "Main.hx", :line_number => 323, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_list_patterns([1, 2, 3, 4, 5]), %{:file_name => "Main.hx", :line_number => 324, :class_name => "Main", :method_name => "testAllPatterns"})

    Log.trace("\nTesting validation states:", %{:file_name => "Main.hx", :line_number => 326, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_validation_state({:valid, %{name: "John", age: 30}}), %{:file_name => "Main.hx", :line_number => 327, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_validation_state({:invalid, ["required field", "invalid format"]}), %{:file_name => "Main.hx", :line_number => 328, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_validation_state({:invalid, "validation failed"}), %{:file_name => "Main.hx", :line_number => 329, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_validation_state({:pending}), %{:file_name => "Main.hx", :line_number => 330, :class_name => "Main", :method_name => "testAllPatterns"})

    Log.trace("\nTesting recursive structures:", %{:file_name => "Main.hx", :line_number => 332, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_recursive_structure({:leaf, 10}), %{:file_name => "Main.hx", :line_number => 333, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_recursive_structure({:node, {:leaf, 5}, {:leaf, 15}}), %{:file_name => "Main.hx", :line_number => 334, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(match_recursive_structure({:node, {:node, {:leaf, 1}, {:leaf, 2}}, {:leaf, 3}}), %{:file_name => "Main.hx", :line_number => 335, :class_name => "Main", :method_name => "testAllPatterns"})

    Log.trace("\nTesting type patterns:", %{:file_name => "Main.hx", :line_number => 337, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(pattern_with_type_test(42), %{:file_name => "Main.hx", :line_number => 338, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(pattern_with_type_test(3.14), %{:file_name => "Main.hx", :line_number => 339, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(pattern_with_type_test("hello"), %{:file_name => "Main.hx", :line_number => 340, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(pattern_with_type_test(true), %{:file_name => "Main.hx", :line_number => 341, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(pattern_with_type_test(:symbol), %{:file_name => "Main.hx", :line_number => 342, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(pattern_with_type_test([1, 2, 3]), %{:file_name => "Main.hx", :line_number => 343, :class_name => "Main", :method_name => "testAllPatterns"})
    Log.trace(pattern_with_type_test(%{a: 1, b: 2}), %{:file_name => "Main.hx", :line_number => 344, :class_name => "Main", :method_name => "testAllPatterns"})
  end

  def main() do
    Log.trace("=== Enhanced Pattern Matching Tests ===", %{:file_name => "Main.hx", :line_number => 348, :class_name => "Main", :method_name => "main"})
    test_all_patterns()
    Log.trace("=== Tests Complete ===", %{:file_name => "Main.hx", :line_number => 350, :class_name => "Main", :method_name => "main"})
  end
end