defmodule Main do
  defp main() do
    test_basic_for_loops()
    test_while_loops()
    test_array_operations()
    test_nested_loops()
    test_loop_control_flow()
    test_complex_patterns()
  end
  defp test_basic_for_loops() do
    Log.trace("=== Basic For Loops ===", %{:fileName => "Main.hx", :lineNumber => 28, :className => "Main", :methodName => "testBasicForLoops"})
    Log.trace("Index: " <> 0, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testBasicForLoops"})
    Log.trace("Index: " <> 1, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testBasicForLoops"})
    Log.trace("Index: " <> 2, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testBasicForLoops"})
    Log.trace("Index: " <> 3, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testBasicForLoops"})
    Log.trace("Index: " <> 4, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testBasicForLoops"})
    Log.trace("Index: " <> 5, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testBasicForLoops"})
    Log.trace("Index: " <> 6, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testBasicForLoops"})
    Log.trace("Index: " <> 7, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testBasicForLoops"})
    Log.trace("Index: " <> 8, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testBasicForLoops"})
    Log.trace("Index: " <> 9, %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "testBasicForLoops"})
    fruits = ["apple", "banana", "orange"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fruits, g, :ok}, fn _, {acc_fruits, acc_g, acc_state} ->
  if (acc_g < acc_fruits.length) do
    fruit = fruits[g]
    acc_g = acc_g + 1
    Log.trace("Fruit: " <> fruit, %{:fileName => "Main.hx", :lineNumber => 38, :className => "Main", :methodName => "testBasicForLoops"})
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
    g = scores.keyValueIterator()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, :ok}, fn _, {acc_g, acc_state} ->
  if (acc_g.hasNext()) do
    acc_g = acc_g.next()
    name = acc_g.key
    score = acc_g.value
    Log.trace("" <> name <> " scored " <> score, %{:fileName => "Main.hx", :lineNumber => 44, :className => "Main", :methodName => "testBasicForLoops"})
    {:cont, {acc_g, acc_state}}
  else
    {:halt, {acc_g, acc_state}}
  end
end)
  end
  defp test_while_loops() do
    Log.trace("=== While Loops ===", %{:fileName => "Main.hx", :lineNumber => 50, :className => "Main", :methodName => "testWhileLoops"})
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, :ok}, fn _, {acc_i, acc_state} ->
  if (acc_i < 5) do
    Log.trace("While: " <> acc_i, %{:fileName => "Main.hx", :lineNumber => 55, :className => "Main", :methodName => "testWhileLoops"})
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
    Log.trace("Break at: " <> acc_j, %{:fileName => "Main.hx", :lineNumber => 63, :className => "Main", :methodName => "testWhileLoops"})
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
    if (acc_k rem 2 != 0) do
      throw(:continue)
    end
    Log.trace("Even: " <> acc_k, %{:fileName => "Main.hx", :lineNumber => 72, :className => "Main", :methodName => "testWhileLoops"})
    {:cont, {acc_k, acc_state}}
  else
    {:halt, {acc_k, acc_state}}
  end
end)
    m = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {m, :ok}, fn _, {acc_m, acc_state} ->
  if (acc_m < 3) do
    Log.trace("Do-while: " <> acc_m, %{:fileName => "Main.hx", :lineNumber => 78, :className => "Main", :methodName => "testWhileLoops"})
    acc_m = acc_m + 1
    {:cont, {acc_m, acc_state}}
  else
    {:halt, {acc_m, acc_state}}
  end
end)
  end
  defp test_array_operations() do
    Log.trace("=== Array Operations ===", %{:fileName => "Main.hx", :lineNumber => 85, :className => "Main", :methodName => "testArrayOperations"})
    numbers = [1, 2, 3, 4, 5]
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    Log.trace("Doubled: " <> Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 91, :className => "Main", :methodName => "testArrayOperations"})
    evens = Enum.filter(numbers, fn n -> n rem 2 == 0 end)
    Log.trace("Evens: " <> Std.string(evens), %{:fileName => "Main.hx", :lineNumber => 95, :className => "Main", :methodName => "testArrayOperations"})
    sum = Lambda.fold(numbers, fn n, acc -> acc + n end, 0)
    Log.trace("Sum with Lambda.fold: " <> sum, %{:fileName => "Main.hx", :lineNumber => 99, :className => "Main", :methodName => "testArrayOperations"})
    tripled = Lambda.map(numbers, fn n -> n * 3 end)
    Log.trace("Tripled with Lambda.map: " <> Std.string(tripled), %{:fileName => "Main.hx", :lineNumber => 103, :className => "Main", :methodName => "testArrayOperations"})
    odds = Lambda.filter(numbers, fn n -> n rem 2 != 0 end)
    Log.trace("Odds with Lambda.filter: " <> Std.string(odds), %{:fileName => "Main.hx", :lineNumber => 107, :className => "Main", :methodName => "testArrayOperations"})
    result = Lambda.fold(Lambda.map(Lambda.filter(numbers, fn n -> n > 2 end), fn n -> n * 3 end), fn n, acc -> acc + n end, 0)
    Log.trace("Chained Lambda result: " <> result, %{:fileName => "Main.hx", :lineNumber => 118, :className => "Main", :methodName => "testArrayOperations"})
    processed = Enum.map(numbers, fn n -> if (n > 3), do: n * 10, else: n + 100 end)
    Log.trace("Processed: " <> Std.string(processed), %{:fileName => "Main.hx", :lineNumber => 128, :className => "Main", :methodName => "testArrayOperations"})
    has_even = Lambda.exists(numbers, fn n -> n rem 2 == 0 end)
    Log.trace("Has even: " <> Std.string(has_even), %{:fileName => "Main.hx", :lineNumber => 132, :className => "Main", :methodName => "testArrayOperations"})
    Lambda.iter(numbers, fn n -> Log.trace("Each: " <> n, %{:fileName => "Main.hx", :lineNumber => 135, :className => "Main", :methodName => "testArrayOperations"}) end)
    found = Lambda.find(numbers, fn n -> n > 3 end)
    Log.trace("Found > 3: " <> found, %{:fileName => "Main.hx", :lineNumber => 139, :className => "Main", :methodName => "testArrayOperations"})
    count_evens = Lambda.count(numbers, fn n -> n rem 2 == 0 end)
    Log.trace("Count evens: " <> count_evens, %{:fileName => "Main.hx", :lineNumber => 143, :className => "Main", :methodName => "testArrayOperations"})
  end
  defp test_nested_loops() do
    Log.trace("=== Nested Loops ===", %{:fileName => "Main.hx", :lineNumber => 148, :className => "Main", :methodName => "testNestedLoops"})
    Log.trace("Nested for: " <> 0 <> ", " <> 0, %{:fileName => "Main.hx", :lineNumber => 153, :className => "Main", :methodName => "testNestedLoops"})
    Log.trace("Nested for: " <> 0 <> ", " <> 1, %{:fileName => "Main.hx", :lineNumber => 153, :className => "Main", :methodName => "testNestedLoops"})
    Log.trace("Nested for: " <> 1 <> ", " <> 0, %{:fileName => "Main.hx", :lineNumber => 153, :className => "Main", :methodName => "testNestedLoops"})
    Log.trace("Nested for: " <> 1 <> ", " <> 1, %{:fileName => "Main.hx", :lineNumber => 153, :className => "Main", :methodName => "testNestedLoops"})
    Log.trace("Nested for: " <> 2 <> ", " <> 0, %{:fileName => "Main.hx", :lineNumber => 153, :className => "Main", :methodName => "testNestedLoops"})
    Log.trace("Nested for: " <> 2 <> ", " <> 1, %{:fileName => "Main.hx", :lineNumber => 153, :className => "Main", :methodName => "testNestedLoops"})
    outer = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {outer, inner, :ok}, fn _, {acc_outer, acc_inner, acc_state} ->
  if (acc_outer < 2) do
    acc_inner = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_inner, :ok}, fn _, {acc_inner, acc_state} ->
  if (acc_inner < 2) do
    Log.trace("Nested while: " <> outer <> ", " <> acc_inner, %{:fileName => "Main.hx", :lineNumber => 162, :className => "Main", :methodName => "testNestedLoops"})
    acc_inner = acc_inner + 1
    {:cont, {acc_inner, acc_state}}
  else
    {:halt, {acc_inner, acc_state}}
  end
end)
    acc_outer = acc_outer + 1
    {:cont, {acc_outer, acc_inner, acc_state}}
  else
    {:halt, {acc_outer, acc_inner, acc_state}}
  end
end)
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, :ok}, fn _, {acc_j, acc_state} ->
  if (acc_j < 2) do
    Log.trace("Mixed: " <> 0 <> ", " <> acc_j, %{:fileName => "Main.hx", :lineNumber => 172, :className => "Main", :methodName => "testNestedLoops"})
    acc_j = acc_j + 1
    {:cont, {acc_j, acc_state}}
  else
    {:halt, {acc_j, acc_state}}
  end
end)
    j = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {j, :ok}, fn _, {acc_j, acc_state} ->
  if (acc_j < 2) do
    Log.trace("Mixed: " <> 1 <> ", " <> acc_j, %{:fileName => "Main.hx", :lineNumber => 172, :className => "Main", :methodName => "testNestedLoops"})
    acc_j = acc_j + 1
    {:cont, {acc_j, acc_state}}
  else
    {:halt, {acc_j, acc_state}}
  end
end)
    matrix = [[1, 2], [3, 4], [5, 6]]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, matrix, :ok}, fn _, {acc_g, acc_matrix, acc_state} ->
  if (acc_g < acc_matrix.length) do
    row = matrix[g]
    acc_g = acc_g + 1
    doubled = Enum.map(row, fn n -> n * 2 end)
    Log.trace("Row doubled: " <> Std.string(doubled), %{:fileName => "Main.hx", :lineNumber => 181, :className => "Main", :methodName => "testNestedLoops"})
    {:cont, {acc_g, acc_matrix, acc_state}}
  else
    {:halt, {acc_g, acc_matrix, acc_state}}
  end
end)
  end
  defp test_loop_control_flow() do
    Log.trace("=== Loop Control Flow ===", %{:fileName => "Main.hx", :lineNumber => 187, :className => "Main", :methodName => "testLoopControlFlow"})
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g, :ok}, fn _, {acc_g, acc_g, acc_state} ->
  if (acc_g < 5) do
    i = acc_g = acc_g + 1
    acc_g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_g, :ok}, fn _, {acc_g, acc_state} ->
  if (acc_g < 5) do
    j = acc_g = acc_g + 1
    if (i + j > 4) do
      throw(:break)
    end
    Log.trace("Before break: " <> i <> ", " <> j, %{:fileName => "Main.hx", :lineNumber => 193, :className => "Main", :methodName => "testLoopControlFlow"})
    {:cont, {acc_g, acc_state}}
  else
    {:halt, {acc_g, acc_state}}
  end
end)
    {:cont, {acc_g, acc_g, acc_state}}
  else
    {:halt, {acc_g, acc_g, acc_state}}
  end
end)
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    processed = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, numbers, :ok}, fn _, {acc_g, acc_numbers, acc_state} ->
  if (acc_g < acc_numbers.length) do
    n = numbers[g]
    acc_g = acc_g + 1
    if (n rem 3 == 0) do
      throw(:continue)
    end
    processed ++ [n * 2]
    {:cont, {acc_g, acc_numbers, acc_state}}
  else
    {:halt, {acc_g, acc_numbers, acc_state}}
  end
end)
    Log.trace("Processed with continue: " <> Std.string(processed), %{:fileName => "Main.hx", :lineNumber => 204, :className => "Main", :methodName => "testLoopControlFlow"})
    find_first = fn arr, target ->
  g = 0
  g1 = arr.length
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
    Log.trace("Found at index: " <> index, %{:fileName => "Main.hx", :lineNumber => 217, :className => "Main", :methodName => "testLoopControlFlow"})
  end
  defp test_complex_patterns() do
    Log.trace("=== Complex Patterns ===", %{:fileName => "Main.hx", :lineNumber => 222, :className => "Main", :methodName => "testComplexPatterns"})
    pairs = []
    pairs = pairs ++ [%{:x => 1, :y => 2}]
    pairs = pairs ++ [%{:x => 1, :y => 3}]
    pairs = pairs ++ [%{:x => 2, :y => 1}]
    pairs = pairs ++ [%{:x => 2, :y => 3}]
    pairs = pairs ++ [%{:x => 3, :y => 1}]
    pairs = pairs ++ [%{:x => 3, :y => 2}]
    nil
    Log.trace("Pairs: " <> Std.string(pairs), %{:fileName => "Main.hx", :lineNumber => 233, :className => "Main", :methodName => "testComplexPatterns"})
    data = [1, 2, 3, 4, 5]
    acc = %{:sum => 0, :count => 0, :product => 1}
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, data, :ok}, fn _, {acc_g, acc_data, acc_state} ->
  if (acc_g < acc_data.length) do
    n = data[g]
    acc_g = acc_g + 1
    sum = acc.sum + n
    acc.count + 1
    product = acc.product * n
    {:cont, {acc_g, acc_data, acc_state}}
  else
    {:halt, {acc_g, acc_data, acc_state}}
  end
end)
    Log.trace("Accumulator: " <> Std.string(acc), %{:fileName => "Main.hx", :lineNumber => 243, :className => "Main", :methodName => "testComplexPatterns"})
    states = ["start", "processing", "done"]
    current_state = 0
    events = ["begin", "work", "work", "finish"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {events, current_state, g, :ok}, fn _, {acc_events, acc_current_state, acc_g, acc_state} ->
  if (acc_g < acc_events.length) do
    event = events[g]
    acc_g = acc_g + 1
    case (event) do
      "begin" ->
        if (acc_current_state == 0) do
          acc_current_state = 1
        end
      "finish" ->
        if (acc_current_state == 1) do
          acc_current_state = 2
        end
      "work" ->
        nil
    end
    Log.trace("State after " <> event <> ": " <> states[current_state], %{:fileName => "Main.hx", :lineNumber => 259, :className => "Main", :methodName => "testComplexPatterns"})
    {:cont, {acc_events, acc_current_state, acc_g, acc_state}}
  else
    {:halt, {acc_events, acc_current_state, acc_g, acc_state}}
  end
end)
    items = ["valid1", "error", "valid2", "valid3"]
    results = []
    errors = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {items, g, :ok}, fn _, {acc_items, acc_g, acc_state} ->
  if (acc_g < acc_items.length) do
    item = items[g]
    acc_g = acc_g + 1
    if (item.indexOf("error") >= 0) do
      errors ++ ["Failed: " <> item]
      throw(:continue)
    end
    results ++ ["Processed: " <> item]
    {:cont, {acc_items, acc_g, acc_state}}
  else
    {:halt, {acc_items, acc_g, acc_state}}
  end
end)
    Log.trace("Results: " <> Std.string(results), %{:fileName => "Main.hx", :lineNumber => 275, :className => "Main", :methodName => "testComplexPatterns"})
    Log.trace("Errors: " <> Std.string(errors), %{:fileName => "Main.hx", :lineNumber => 276, :className => "Main", :methodName => "testComplexPatterns"})
  end
end