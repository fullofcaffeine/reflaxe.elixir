defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    array = [1, 2, 3, 4, 5]

    result = []

    g_counter = 0
    Enum.filter(array, fn item -> item > 2 end)

    g_counter = 0
    g_array = g_array.length
    g_array
    |> Enum.with_index()
    |> Enum.each(fn {item, j} ->
      i = g_counter + 1
      g_counter = 0
      g_array = g_array.length
      g_array
      |> Enum.with_index()
      |> Enum.map(fn {item, i} -> (item + item) end)
    end)

    filtered = []

    g_counter = 0
    Enum.filter(array, fn item -> rem(item, 2) == 0 end)

    functions = []

    functions ++ [fn  -> 0 end]

    functions ++ [fn  -> 1 end]

    functions ++ [fn  -> 2 end]

    i = 100

    result ++ [0]

    result ++ [1]

    result ++ [2]

    result ++ [i]

    sum = 0

    g_counter = 0
    Enum.each(g_array, fn n -> 
      sum = sum + n
    end)

    g_counter = 0
    Enum.each(g_array, fn n -> 
      sum = sum - n
    end)

    Log.trace(result, %{"fileName" => "Main.hx", "lineNumber" => 54, "className" => "Main", "methodName" => "main"})

    Log.trace(filtered, %{"fileName" => "Main.hx", "lineNumber" => 55, "className" => "Main", "methodName" => "main"})

    Log.trace("Functions count: " <> to_string(functions.length), %{"fileName" => "Main.hx", "lineNumber" => 56, "className" => "Main", "methodName" => "main"})

    Log.trace("Sum after reuse: " <> to_string(sum), %{"fileName" => "Main.hx", "lineNumber" => 57, "className" => "Main", "methodName" => "main"})
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
