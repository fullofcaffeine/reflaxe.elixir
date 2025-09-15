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

    # Range iteration
    Enum.each(0..9, fn i ->
      Log.trace("Index: #{i}", %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "testBasicForLoops"})
    end)

    # Array iteration
    fruits = ["apple", "banana", "orange"]
    Enum.each(fruits, fn fruit ->
      Log.trace("Fruit: #{fruit}", %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "testBasicForLoops"})
    end)

    # Map iteration
    scores = %{"Alice" => 95, "Bob" => 87, "Charlie" => 92}
    Enum.each(scores, fn {name, score} ->
      Log.trace("#{name} scored #{score}", %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "testBasicForLoops"})
    end)
  end

  defp test_while_loops() do
    Log.trace("=== While Loops ===", %{:file_name => "Main.hx", :line_number => 50, :class_name => "Main", :method_name => "testWhileLoops"})

    # Basic while - using recursive function
    defp while_loop(i) when i < 5 do
      Log.trace("While: #{i}", %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "testWhileLoops"})
      while_loop(i + 1)
    end
    defp while_loop(_i), do: :ok
    while_loop(0)

    # While with break - using recursive function with early termination
    defp break_loop(j) when j >= 3, do: :ok
    defp break_loop(j) do
      Log.trace("Break at: #{j}", %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "testWhileLoops"})
      break_loop(j + 1)
    end
    break_loop(0)

    # While with continue - using recursive function with conditional logic
    defp continue_loop(k) when k >= 10, do: :ok
    defp continue_loop(k) do
      next_k = k + 1
      if rem(next_k, 2) == 0 do
        Log.trace("Even: #{next_k}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "testWhileLoops"})
      end
      continue_loop(next_k)
    end
    continue_loop(0)

    # Do-while - using recursive function that runs at least once
    defp do_while_loop(m) do
      Log.trace("Do-while: #{m}", %{:file_name => "Main.hx", :line_number => 78, :class_name => "Main", :method_name => "testWhileLoops"})
      if m + 1 < 3, do: do_while_loop(m + 1)
    end
    do_while_loop(0)
  end

  defp test_array_operations() do
    Log.trace("=== Array Operations ===", %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "testArrayOperations"})

    numbers = [1, 2, 3, 4, 5]

    # Map - Enum.map
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    Log.trace("Doubled: #{inspect(doubled)}", %{:file_name => "Main.hx", :line_number => 91, :class_name => "Main", :method_name => "testArrayOperations"})

    # Filter - Enum.filter
    evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Evens: #{inspect(evens)}", %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "testArrayOperations"})

    # Lambda.fold - Enum.reduce
    sum = Enum.reduce(numbers, 0, fn n, acc -> acc + n end)
    Log.trace("Sum with Lambda.fold: #{sum}", %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "testArrayOperations"})

    # Lambda.map - Enum.map
    tripled = Enum.map(numbers, fn n -> n * 3 end)
    Log.trace("Tripled with Lambda.map: #{inspect(tripled)}", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "testArrayOperations"})

    # Lambda.filter - Enum.filter
    odds = Enum.filter(numbers, fn n -> rem(n, 2) != 0 end)
    Log.trace("Odds with Lambda.filter: #{inspect(odds)}", %{:file_name => "Main.hx", :line_number => 107, :class_name => "Main", :method_name => "testArrayOperations"})

    # Chained operations with pipeline
    result = numbers
      |> Enum.filter(fn n -> n > 2 end)
      |> Enum.map(fn n -> n * 3 end)
      |> Enum.reduce(0, fn n, acc -> acc + n end)
    Log.trace("Chained Lambda result: #{result}", %{:file_name => "Main.hx", :line_number => 118, :class_name => "Main", :method_name => "testArrayOperations"})

    # Complex map with conditionals
    processed = Enum.map(numbers, fn n ->
      if n > 3, do: n * 10, else: n + 100
    end)
    Log.trace("Processed: #{inspect(processed)}", %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "testArrayOperations"})

    # Lambda.exists - Enum.any?
    has_even = Enum.any?(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Has even: #{has_even}", %{:file_name => "Main.hx", :line_number => 132, :class_name => "Main", :method_name => "testArrayOperations"})

    # Lambda.iter - Enum.each
    Enum.each(numbers, fn n ->
      Log.trace("Each: #{n}", %{:file_name => "Main.hx", :line_number => 135, :class_name => "Main", :method_name => "testArrayOperations"})
    end)

    # Lambda.find - Enum.find
    found = Enum.find(numbers, fn n -> n > 3 end)
    Log.trace("Found > 3: #{found}", %{:file_name => "Main.hx", :line_number => 139, :class_name => "Main", :method_name => "testArrayOperations"})

    # Lambda.count - Enum.count
    count_evens = Enum.count(numbers, fn n -> rem(n, 2) == 0 end)
    Log.trace("Count evens: #{count_evens}", %{:file_name => "Main.hx", :line_number => 143, :class_name => "Main", :method_name => "testArrayOperations"})
  end

  defp test_nested_loops() do
    Log.trace("=== Nested Loops ===", %{:file_name => "Main.hx", :line_number => 148, :class_name => "Main", :method_name => "testNestedLoops"})

    # Nested for loops - using comprehensions
    for i <- 0..2, j <- 0..1 do
      Log.trace("Nested for: #{i}, #{j}", %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "testNestedLoops"})
    end

    # Nested while loops - using nested recursive functions
    defp outer_loop(outer) when outer < 2 do
      defp inner_loop(outer, inner) when inner < 2 do
        Log.trace("Nested while: #{outer}, #{inner}", %{:file_name => "Main.hx", :line_number => 162, :class_name => "Main", :method_name => "testNestedLoops"})
        inner_loop(outer, inner + 1)
      end
      defp inner_loop(_outer, _inner), do: :ok
      inner_loop(outer, 0)
      outer_loop(outer + 1)
    end
    defp outer_loop(_outer), do: :ok
    outer_loop(0)

    # Mixed nesting - comprehension with nested loop
    for i <- 0..1 do
      defp mixed_loop(i, j) when j < 2 do
        Log.trace("Mixed: #{i}, #{j}", %{:file_name => "Main.hx", :line_number => 172, :class_name => "Main", :method_name => "testNestedLoops"})
        mixed_loop(i, j + 1)
      end
      defp mixed_loop(_i, _j), do: :ok
      mixed_loop(i, 0)
    end

    # Array operations inside loops
    matrix = [[1, 2], [3, 4], [5, 6]]
    Enum.each(matrix, fn row ->
      doubled = Enum.map(row, fn n -> n * 2 end)
      Log.trace("Row doubled: #{inspect(doubled)}", %{:file_name => "Main.hx", :line_number => 181, :class_name => "Main", :method_name => "testNestedLoops"})
    end)
  end

  defp test_loop_control_flow() do
    Log.trace("=== Loop Control Flow ===", %{:file_name => "Main.hx", :line_number => 187, :class_name => "Main", :method_name => "testLoopControlFlow"})

    # Break in nested loops - using comprehension with filtering
    for i <- 0..4, j <- 0..4, i + j <= 4 do
      Log.trace("Before break: #{i}, #{j}", %{:file_name => "Main.hx", :line_number => 193, :class_name => "Main", :method_name => "testLoopControlFlow"})
    end

    # Continue in array operations - using filter and map
    numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    processed = numbers
      |> Enum.filter(fn n -> rem(n, 3) != 0 end)
      |> Enum.map(fn n -> n * 2 end)
    Log.trace("Processed with continue: #{inspect(processed)}", %{:file_name => "Main.hx", :line_number => 204, :class_name => "Main", :method_name => "testLoopControlFlow"})

    # Early return from loop
    find_first = fn arr, target ->
      Enum.find_index(arr, fn x -> x == target end) || -1
    end

    index = find_first.([10, 20, 30, 40], 30)
    Log.trace("Found at index: #{index}", %{:file_name => "Main.hx", :line_number => 217, :class_name => "Main", :method_name => "testLoopControlFlow"})
  end

  defp test_complex_patterns() do
    Log.trace("=== Complex Patterns ===", %{:file_name => "Main.hx", :line_number => 222, :class_name => "Main", :method_name => "testComplexPatterns"})

    # List comprehension-like pattern
    pairs = for i <- 1..3, j <- 1..3, i != j do
      %{x: i, y: j}
    end
    Log.trace("Pairs: #{inspect(pairs)}", %{:file_name => "Main.hx", :line_number => 233, :class_name => "Main", :method_name => "testComplexPatterns"})

    # Accumulator pattern
    data = [1, 2, 3, 4, 5]
    acc = Enum.reduce(data, %{sum: 0, count: 0, product: 1}, fn n, acc ->
      %{acc | sum: acc.sum + n, count: acc.count + 1, product: acc.product * n}
    end)
    Log.trace("Accumulator: #{inspect(acc)}", %{:file_name => "Main.hx", :line_number => 243, :class_name => "Main", :method_name => "testComplexPatterns"})

    # State machine pattern
    states = ["start", "processing", "done"]
    events = ["begin", "work", "work", "finish"]

    {final_state, _} = Enum.reduce(events, {0, states}, fn event, {current_state, states} ->
      new_state = case {event, current_state} do
        {"begin", 0} -> 1
        {"finish", 1} -> 2
        _ -> current_state
      end
      Log.trace("State after #{event}: #{Enum.at(states, new_state)}", %{:file_name => "Main.hx", :line_number => 259, :class_name => "Main", :method_name => "testComplexPatterns"})
      {new_state, states}
    end)

    # Real-world: process batch with error handling
    items = ["valid1", "error", "valid2", "valid3"]
    {results, errors} = Enum.reduce(items, {[], []}, fn item, {results, errors} ->
      if String.contains?(item, "error") do
        {results, errors ++ ["Failed: #{item}"]}
      else
        {results ++ ["Processed: #{item}"], errors}
      end
    end)

    Log.trace("Results: #{inspect(results)}", %{:file_name => "Main.hx", :line_number => 275, :class_name => "Main", :method_name => "testComplexPatterns"})
    Log.trace("Errors: #{inspect(errors)}", %{:file_name => "Main.hx", :line_number => 276, :class_name => "Main", :method_name => "testComplexPatterns"})
  end
end