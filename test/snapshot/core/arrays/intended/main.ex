defmodule Main do
  def basic_array_ops() do
    numbers = [1, 2, 3, 4, 5]
    IO.inspect(Enum.at(numbers, 0))  # First element
    IO.inspect(length(numbers))      # Length

    # Array modification (immutable operations)
    numbers = numbers ++ [6]          # push
    numbers = [0 | numbers]           # unshift
    popped = List.last(numbers)      # pop (get last)
    shifted = List.first(numbers)    # shift (get first)
    IO.puts("Popped: #{popped}, Shifted: #{shifted}")

    # Array of different types
    mixed = [1, "hello", true, 3.14]
    IO.inspect(mixed)
  end

  def array_iteration() do
    fruits = ["apple", "banana", "orange", "grape"]

    # For loop
    for fruit <- fruits do
      IO.puts("Fruit: #{fruit}")
    end

    # For with index
    for {fruit, i} <- Enum.with_index(fruits) do
      IO.puts("#{i}: #{fruit}")
    end

    # While iteration (using recursion in Elixir)
    iterate_fruits(fruits, 0)
  end

  defp iterate_fruits([], _), do: :ok
  defp iterate_fruits([fruit | rest], index) do
    IO.puts("While: #{fruit}")
    iterate_fruits(rest, index + 1)
  end

  def array_methods() do
    numbers = [1, 2, 3, 4, 5]

    # Map
    doubled = Enum.map(numbers, fn n -> n * 2 end)
    IO.puts("Doubled: #{inspect(doubled)}")

    # Filter
    evens = Enum.filter(numbers, fn n -> rem(n, 2) == 0 end)
    IO.puts("Evens: #{inspect(evens)}")

    # Concat
    more = [6, 7, 8]
    combined = numbers ++ more
    IO.puts("Combined: #{inspect(combined)}")

    # Join
    words = ["Hello", "World", "from", "Haxe"]
    sentence = Enum.join(words, " ")
    IO.puts("Sentence: #{sentence}")

    # Reverse
    reversed = Enum.reverse(numbers)
    IO.puts("Reversed: #{inspect(reversed)}")

    # Sort
    unsorted = [3, 1, 4, 1, 5, 9, 2, 6]
    sorted = Enum.sort(unsorted)
    IO.puts("Sorted: #{inspect(sorted)}")
  end

  def array_comprehensions() do
    # Simple comprehension
    squares = for i <- 1..5, do: i * i
    IO.puts("Squares: #{inspect(squares)}")

    # Comprehension with condition
    even_squares = for i <- 1..9, rem(i, 2) == 0, do: i * i
    IO.puts("Even squares: #{inspect(even_squares)}")

    # Nested comprehension
    pairs = for x <- 1..3, y <- 1..3, x != y, do: %{x: x, y: y}
    IO.puts("Pairs: #{inspect(pairs)}")
  end

  def multi_dimensional() do
    # 2D array
    matrix = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9]
    ]

    IO.puts("Matrix element [1][2]: #{Enum.at(Enum.at(matrix, 1), 2)}")

    # Iterate 2D array
    for row <- matrix do
      for elem <- row do
        IO.puts("Element: #{elem}")
      end
    end

    # Create dynamic 2D array
    grid = for i <- 0..2, do: for j <- 0..2, do: i * 3 + j
    IO.puts("Grid: #{inspect(grid)}")
  end

  def process_array(arr) do
    arr
    |> Enum.map(fn x -> x * x end)
    |> Enum.filter(fn x -> x > 10 end)
  end

  def first_n(arr, n) do
    Enum.take(arr, n)
  end

  def functional_methods() do
    numbers = [1, 2, 3, 4, 5]
    strings = ["hello", "world", "haxe", "elixir"]

    # Test reduce/fold - accumulation operations
    sum = Enum.reduce(numbers, 0, fn item, acc -> acc + item end)
    IO.puts("Sum via reduce: #{sum}")

    product = Enum.reduce(numbers, 1, fn item, acc -> acc * item end)
    IO.puts("Product via fold: #{product}")

    # Test find - search for first match
    first_even = Enum.find(numbers, fn n -> rem(n, 2) == 0 end)
    IO.puts("First even number: #{first_even}")

    long_word = Enum.find(strings, fn s -> String.length(s) > 4 end)
    IO.puts("First long word: #{long_word}")

    # Test findIndex - get index of first match
    even_index = Enum.find_index(numbers, fn n -> rem(n, 2) == 0 end)
    IO.puts("Index of first even: #{even_index}")

    long_word_index = Enum.find_index(strings, fn s -> String.length(s) > 4 end)
    IO.puts("Index of first long word: #{long_word_index}")

    # Test exists/any - check if any element matches
    has_even = Enum.any?(numbers, fn n -> rem(n, 2) == 0 end)
    IO.puts("Has even numbers: #{has_even}")

    has_very_long = Enum.any?(strings, fn s -> String.length(s) > 10 end)
    IO.puts("Has very long word: #{has_very_long}")

    # Test foreach/all - check if all elements match
    all_positive = Enum.all?(numbers, fn n -> n > 0 end)
    IO.puts("All positive: #{all_positive}")

    all_short = Enum.all?(strings, fn s -> String.length(s) < 10 end)
    IO.puts("All short words: #{all_short}")

    # Test forEach - side effects
    IO.puts("Numbers via forEach:")
    Enum.each(numbers, fn n -> IO.puts("  - #{n}") end)

    # Test take - get first n elements
    first3 = Enum.take(numbers, 3)
    IO.puts("First 3 numbers: #{inspect(first3)}")

    # Test drop - skip first n elements
    skip2 = Enum.drop(numbers, 2)
    IO.puts("Skip first 2: #{inspect(skip2)}")

    # Test flatMap - map and flatten
    nested_arrays = [[1, 2], [3, 4], [5]]
    flattened = Enum.flat_map(nested_arrays, fn arr -> Enum.map(arr, fn x -> x * 2 end) end)
    IO.puts("FlatMap doubled: #{inspect(flattened)}")

    # Test chaining functional methods
    processed = numbers
    |> Enum.filter(fn n -> n > 2 end)       # [3, 4, 5]
    |> Enum.map(fn n -> n * n end)          # [9, 16, 25]
    |> Enum.take(2)                          # [9, 16]
    |> Enum.reduce(0, fn n, acc -> acc + n end)  # 25
    IO.puts("Chained operations result: #{processed}")
  end

  def main() do
    IO.puts("=== Basic Array Operations ===")
    basic_array_ops()

    IO.puts("\n=== Array Iteration ===")
    array_iteration()

    IO.puts("\n=== Array Methods ===")
    array_methods()

    IO.puts("\n=== Array Comprehensions ===")
    array_comprehensions()

    IO.puts("\n=== Multi-dimensional Arrays ===")
    multi_dimensional()

    IO.puts("\n=== Array Functions ===")
    result = process_array([1, 2, 3, 4, 5])
    IO.puts("Processed: #{inspect(result)}")

    first3 = first_n(["a", "b", "c", "d", "e"], 3)
    IO.puts("First 3: #{inspect(first3)}")

    IO.puts("\n=== NEW: Functional Array Methods ===")
    functional_methods()
  end
end