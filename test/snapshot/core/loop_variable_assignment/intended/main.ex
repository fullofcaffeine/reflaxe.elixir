defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    temp_array = nil
    temp_array1 = nil
    temp_array2 = nil

    numbers = [1, 2, 3, 4, 5]

    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < numbers.length)) do
            n = Enum.at(numbers, g_counter)
        g_counter + 1
        g_array = g_array ++ [(n * 2)]
        loop.()
      end
    end).()
    temp_array = g_array

    Log.trace("Doubled: " <> Std.string(temp_array), %{"fileName" => "Main.hx", "lineNumber" => 9, "className" => "Main", "methodName" => "main"})

    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < numbers.length)) do
            n = Enum.at(numbers, g_counter)
        g_counter + 1
        g_array = if ((rem(n, 2) == 0)), do: g_array ++ [n], else: g_array
        loop.()
      end
    end).()
    temp_array1 = g_array

    Log.trace("Evens: " <> Std.string(temp_array1), %{"fileName" => "Main.hx", "lineNumber" => 13, "className" => "Main", "methodName" => "main"})

    g_array = []
    x = 1
    y = "a"
    g_array = g_array ++ [%{"x" => x, "y" => y}]
    y = "b"
    g_array = g_array ++ [%{"x" => x, "y" => y}]
    x = 2
    y = "a"
    g_array = g_array ++ [%{"x" => x, "y" => y}]
    y = "b"
    g_array = g_array ++ [%{"x" => x, "y" => y}]
    temp_array2 = g_array

    Log.trace("Pairs: " <> Std.string(temp_array2), %{"fileName" => "Main.hx", "lineNumber" => 19, "className" => "Main", "methodName" => "main"})

    i = 0

    collected = []

    (fn loop ->
      if ((i < 5)) do
            collected = collected ++ [(i * i)]
        i + 1
        loop.()
      end
    end).()

    Log.trace("Collected squares: " <> Std.string(collected), %{"fileName" => "Main.hx", "lineNumber" => 28, "className" => "Main", "methodName" => "main"})

    j = 0

    results = []

    (fn loop ->
        results = results ++ [j]
      j + 1
      if ((j < 3)) do
        loop.()
      end
    end).()

    Log.trace("Do-while results: " <> Std.string(results), %{"fileName" => "Main.hx", "lineNumber" => 37, "className" => "Main", "methodName" => "main"})

    sum = 0

    g_counter = 0
    (fn loop ->
      if ((g_counter < numbers.length)) do
            n = Enum.at(numbers, g_counter)
        g_counter + 1
        sum = sum + n
        loop.()
      end
    end).()

    Log.trace("Sum: " <> to_string(sum), %{"fileName" => "Main.hx", "lineNumber" => 44, "className" => "Main", "methodName" => "main"})

    output = []

    g_counter = 0
    (fn loop ->
      if ((g_counter < numbers.length)) do
            n = Enum.at(numbers, g_counter)
        g_counter + 1
        output = if ((n > 2)), do: output ++ [n], else: output
        loop.()
      end
    end).()

    Log.trace("Filtered output: " <> Std.string(output), %{"fileName" => "Main.hx", "lineNumber" => 53, "className" => "Main", "methodName" => "main"})
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
