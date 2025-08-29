defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    array = [1, 2, 3, 4, 5]

    result = []

    g_counter = 0
    (fn loop ->
      if ((g_counter < array.length)) do
            item = Enum.at(array, g_counter)
        g_counter + 1
        result = if ((item > 2)), do: result ++ [(item * 2)], else: result
        loop.()
      end
    end).()

    g_counter = 0
    g_array = array.length
    (fn loop ->
      if ((g_counter < g_array)) do
            i = g_counter + 1
        g_counter = 0
        g_array = array.length
        (fn loop ->
          if ((g_counter < g_array)) do
                j = g_counter + 1
            result = if ((Enum.at(array, i) < Enum.at(array, j))), do: result ++ [(Enum.at(array, i) + Enum.at(array, j))], else: result
            loop.()
          end
        end).()
        loop.()
      end
    end).()

    filtered = []

    g_counter = 0
    (fn loop ->
      if ((g_counter < array.length)) do
            x = Enum.at(array, g_counter)
        g_counter + 1
        filtered = if ((rem(x, 2) == 0)), do: filtered ++ [x], else: filtered
        loop.()
      end
    end).()

    functions = []

    functions = functions ++ [fn  -> 0 end]

    functions = functions ++ [fn  -> 1 end]

    functions = functions ++ [fn  -> 2 end]

    i = 100

    result = result ++ [0]

    result = result ++ [1]

    result = result ++ [2]

    result = result ++ [i]

    sum = 0

    g_counter = 0
    (fn loop ->
      if ((g_counter < array.length)) do
            n = Enum.at(array, g_counter)
        g_counter + 1
        sum = sum + n
        loop.()
      end
    end).()

    g_counter = 0
    (fn loop ->
      if ((g_counter < array.length)) do
            n = Enum.at(array, g_counter)
        g_counter + 1
        sum = sum - n
        loop.()
      end
    end).()

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
