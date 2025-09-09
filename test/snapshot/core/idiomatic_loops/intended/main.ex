defmodule Main do
  def main() do
    test_basic_for_loops()
    test_while_loops()
    test_array_operations()
    test_nested_loops()
    test_loop_control_flow()
    test_complex_patterns()
  end
  defp test_basic_for_loops() do
    Log.trace("=== Basic For Loops ===", %{:file_name => "Main.hx", :line_number => 28, :class_name => "Main", :method_name => "testBasicForLoops"})
    Log.trace("Index: " <> Kernel.to_string(0), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    Log.trace("Index: " <> Kernel.to_string(1), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    Log.trace("Index: " <> Kernel.to_string(2), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    Log.trace("Index: " <> Kernel.to_string(3), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    Log.trace("Index: " <> Kernel.to_string(4), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    Log.trace("Index: " <> Kernel.to_string(5), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    Log.trace("Index: " <> Kernel.to_string(6), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    Log.trace("Index: " <> Kernel.to_string(7), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    Log.trace("Index: " <> Kernel.to_string(8), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    Log.trace("Index: " <> Kernel.to_string(9), %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    fruits = ["apple", "banana", "orange"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits, g, :ok}, fn _, {acc_fruits, acc_g, acc_state} ->
  if (acc_g < length(acc_fruits)) do
    fruit = fruits[g]
    acc_g = acc_g + 1
    Log.trace("Fruit: " <> fruit, %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "testBasicForLoops"})
    {:cont, {acc_fruits, acc_g, acc_state}}
  else
    {:halt, {acc_fruits, acc_g, acc_state}}
  end
end)
    g = %{}
    g = Map.put(g, "Alice", 95)
    g = Map.put(g, "Bob", 87)
    g = Map.put(g, "Charlie", 92)
    scores = g
    g = scores.key_value_iterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, :ok}, fn _, {acc_g, acc_state} -> nil end)
  end
  defp test_while_loops() do
    Log.trace("=== While Loops ===", %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "testWhileLoops"})
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, :ok}, fn _, {acc_i, acc_state} ->
  if (acc_i < 5) do
    Log.trace("While: " <> Kernel.to_string(acc_i), %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "testWhileLoops"})
    acc_i = acc_i + 1
    {:cont, {acc_i, acc_state}}
  else
    {:halt, {acc_i, acc_state}}
  end
end)
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, :ok}, fn _, {acc_j, acc_state} ->
  if true do
    if (acc_j >= 3) do
      throw(:break)
    end
    Log.trace("Break at: " <> Kernel.to_string(acc_j), %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "testWhileLoops"})
    acc_j = acc_j + 1
    {:cont, {acc_j, acc_state}}
  else
    {:halt, {acc_j, acc_state}}
  end
end)
    k = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k, :ok}, fn _, {acc_k, acc_state} ->
  if (acc_k < 10) do
    acc_k = acc_k + 1
    if (rem(acc_k, 2) != 0) do
      throw(:continue)
    end
    Log.trace("Even: " <> Kernel.to_string(acc_k), %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "testWhileLoops"})
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
  end
end)
    m = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {m, :ok}, fn _, {acc_m, acc_state} ->
  if (acc_m < 3) do
    Log.trace("Do-while: " <> Kernel.to_string(acc_m), %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "testWhileLoops"})
    acc_m = acc_m + 1
    {:cont, {acc_m, acc_state}}
  else
    {:halt, {acc_m, acc_state}}
  end
end)
  end
  defp test_array_operations() do
    Log.trace("=== Array Operations ===", %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "testArrayOperations"})
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    Log.trace("Doubled: " <> Std.string(doubled), %{:file_name => "Main.hx", :line_number => 91, :class_name => "Main", :method_name => "testArrayOperations"})
    evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Evens: " <> Std.string(evens), %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "testArrayOperations"})
    sum = Lambda.fold(numbers, fn n, acc -> acc + n end, 0)
    Log.trace("Sum with Lambda.fold: " <> Kernel.to_string(sum), %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "testArrayOperations"})
    tripled = Lambda.map(numbers, fn n -> n * 3 end)
    Log.trace("Tripled with Lambda.map: " <> Std.string(tripled), %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testArrayOperations"})
    odds = Lambda.filter(numbers, fn n -> rem(n, 2) != 0 end)
    Log.trace("Odds with Lambda.filter: " <> Std.string(odds), %{:file_name => "Main.hx", :line_number => 107, :class_name => "Main", :method_name => "testArrayOperations"})
    result = Lambda.fold(Lambda.map(Lambda.filter(numbers, fn n -> n > 2 end), fn n -> n * 3 end), fn n, acc -> acc + n end, 0)
    Log.trace("Chained Lambda result: " <> Kernel.to_string(result), %{:file_name => "Main.hx", :line_number => 118, :class_name => "Main", :method_name => "testArrayOperations"})
    processed = Enum.map(numbers, fn n -> if (n > 3), do: n * 10, else: n + 100 end)
    Log.trace("Processed: " <> Std.string(processed), %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "testArrayOperations"})
    has_even = Lambda.exists(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Has even: " <> Std.string(has_even), %{:file_name => "Main.hx", :line_number => 132, :class_name => "Main", :method_name => "testArrayOperations"})
    Lambda.iter(numbers, fn n -> Log.trace("Each: " <> Kernel.to_string(n), %{:file_name => "Main.hx", :line_number => 135, :class_name => "Main", :method_name => "testArrayOperations"}) end)
    found = Lambda.find(numbers, fn n -> n > 3 end)
    Log.trace("Found > 3: " <> Kernel.to_string(found), %{:file_name => "Main.hx", :line_number => 139, :class_name => "Main", :method_name => "testArrayOperations"})
    count_evens = Lambda.count(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Count evens: " <> Kernel.to_string(count_evens), %{:file_name => "Main.hx", :line_number => 143, :class_name => "Main", :method_name => "testArrayOperations"})
  end
  defp test_nested_loops() do
    Log.trace("=== Nested Loops ===", %{:file_name => "Main.hx", :line_number => 148, :class_name => "Main", :method_name => "testNestedLoops"})
    Log.trace("Nested for: " <> Kernel.to_string(0) <> ", " <> Kernel.to_string(0), %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "testNestedLoops"})
    Log.trace("Nested for: " <> Kernel.to_string(0) <> ", " <> Kernel.to_string(1), %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "testNestedLoops"})
    Log.trace("Nested for: " <> Kernel.to_string(1) <> ", " <> Kernel.to_string(0), %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "testNestedLoops"})
    Log.trace("Nested for: " <> Kernel.to_string(1) <> ", " <> Kernel.to_string(1), %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "testNestedLoops"})
    Log.trace("Nested for: " <> Kernel.to_string(2) <> ", " <> Kernel.to_string(0), %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "testNestedLoops"})
    Log.trace("Nested for: " <> Kernel.to_string(2) <> ", " <> Kernel.to_string(1), %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "testNestedLoops"})
    outer = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {inner, outer, :ok}, fn _, {acc_inner, acc_outer, acc_state} -> nil end)
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, :ok}, fn _, {acc_j, acc_state} ->
  if (acc_j < 2) do
    Log.trace("Mixed: " <> Kernel.to_string(0) <> ", " <> Kernel.to_string(acc_j), %{:file_name => "Main.hx", :line_number => 172, :class_name => "Main", :method_name => "testNestedLoops"})
    acc_j = acc_j + 1
    {:cont, {acc_j, acc_state}}
  else
    {:halt, {acc_j, acc_state}}
  end
end)
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, :ok}, fn _, {acc_j, acc_state} ->
  if (acc_j < 2) do
    Log.trace("Mixed: " <> Kernel.to_string(1) <> ", " <> Kernel.to_string(acc_j), %{:file_name => "Main.hx", :line_number => 172, :class_name => "Main", :method_name => "testNestedLoops"})
    acc_j = acc_j + 1
    {:cont, {acc_j, acc_state}}
  else
    {:halt, {acc_j, acc_state}}
  end
end)
    matrix = [[1, 2], [3, 4], [5, 6]]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {matrix, g, :ok}, fn _, {acc_matrix, acc_g, acc_state} ->
  if (acc_g < length(acc_matrix)) do
    row = matrix[g]
    acc_g = acc_g + 1
    doubled = Enum.map(row, fn n -> n * 2 end)
    Log.trace("Row doubled: " <> Std.string(doubled), %{:file_name => "Main.hx", :line_number => 181, :class_name => "Main", :method_name => "testNestedLoops"})
    {:cont, {acc_matrix, acc_g, acc_state}}
  else
    {:halt, {acc_matrix, acc_g, acc_state}}
  end
end)
  end
  defp test_loop_control_flow() do
    Log.trace("=== Loop Control Flow ===", %{:file_name => "Main.hx", :line_number => 187, :class_name => "Main", :method_name => "testLoopControlFlow"})
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g, :ok}, fn _, {acc_g, acc_g, acc_state} -> nil end)
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    processed = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, numbers, :ok}, fn _, {acc_g, acc_numbers, acc_state} ->
  if (acc_g < length(acc_numbers)) do
    n = numbers[g]
    acc_g = acc_g + 1
    if (rem(n, 3) == 0) do
      throw(:continue)
    end
    processed ++ [n * 2]
    {:cont, {acc_g, acc_numbers, acc_state}}
  else
    {:halt, {acc_g, acc_numbers, acc_state}}
  end
end)
    Log.trace("Processed with continue: " <> Std.string(processed), %{:file_name => "Main.hx", :line_number => 204, :class_name => "Main", :method_name => "testLoopControlFlow"})
    find_first = fn arr, target ->
  g = 0
  g1 = length(arr)
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    if (arr[i] == target), do: i
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
  -1
end
    index = find_first.([10, 20, 30, 40], 30)
    Log.trace("Found at index: " <> Kernel.to_string(index), %{:file_name => "Main.hx", :line_number => 217, :class_name => "Main", :method_name => "testLoopControlFlow"})
  end
  defp test_complex_patterns() do
    Log.trace("=== Complex Patterns ===", %{:file_name => "Main.hx", :line_number => 222, :class_name => "Main", :method_name => "testComplexPatterns"})
    pairs = []
    pairs = pairs ++ [%{:x => 1, :y => 2}]
    pairs = pairs ++ [%{:x => 1, :y => 3}]
    pairs = pairs ++ [%{:x => 2, :y => 1}]
    pairs = pairs ++ [%{:x => 2, :y => 3}]
    pairs = pairs ++ [%{:x => 3, :y => 1}]
    pairs = pairs ++ [%{:x => 3, :y => 2}]
    nil
    Log.trace("Pairs: " <> Std.string(pairs), %{:file_name => "Main.hx", :line_number => 233, :class_name => "Main", :method_name => "testComplexPatterns"})
    data = [1, 2, 3, 4, 5]
    acc = %{:sum => 0, :count => 0, :product => 1}
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {data, g, :ok}, fn _, {acc_data, acc_g, acc_state} ->
  if (acc_g < length(acc_data)) do
    n = data[g]
    acc_g = acc_g + 1
    sum = acc.sum + n
    acc.count + 1
    product = acc.product * n
    {:cont, {acc_data, acc_g, acc_state}}
  else
    {:halt, {acc_data, acc_g, acc_state}}
  end
end)
    Log.trace("Accumulator: " <> Std.string(acc), %{:file_name => "Main.hx", :line_number => 243, :class_name => "Main", :method_name => "testComplexPatterns"})
    states = ["start", "processing", "done"]
    current_state = 0
    events = ["begin", "work", "work", "finish"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {current_state, g, events, :ok}, fn _, {acc_current_state, acc_g, acc_events, acc_state} ->
  if (acc_g < length(acc_events)) do
    event = events[g]
    acc_g = acc_g + 1
    case (event) do
      "begin" ->
        nil
      "finish" ->
        nil
      "work" ->
        nil
    end
    Log.trace("State after " <> event <> ": " <> states[current_state], %{:file_name => "Main.hx", :line_number => 259, :class_name => "Main", :method_name => "testComplexPatterns"})
    {:cont, {acc_current_state, acc_g, acc_events, acc_state}}
  else
    {:halt, {acc_current_state, acc_g, acc_events, acc_state}}
  end
end)
    items = ["valid1", "error", "valid2", "valid3"]
    results = []
    errors = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, g, :ok}, fn _, {acc_items, acc_g, acc_state} ->
  if (acc_g < length(acc_items)) do
    item = items[g]
    acc_g = acc_g + 1
    if (item.index_of("error") >= 0) do
      errors ++ ["Failed: " <> item]
      throw(:continue)
    end
    results ++ ["Processed: " <> item]
    {:cont, {acc_items, acc_g, acc_state}}
  else
    {:halt, {acc_items, acc_g, acc_state}}
  end
end)
    Log.trace("Results: " <> Std.string(results), %{:file_name => "Main.hx", :line_number => 275, :class_name => "Main", :method_name => "testComplexPatterns"})
    Log.trace("Errors: " <> Std.string(errors), %{:file_name => "Main.hx", :line_number => 276, :class_name => "Main", :method_name => "testComplexPatterns"})
  end
end