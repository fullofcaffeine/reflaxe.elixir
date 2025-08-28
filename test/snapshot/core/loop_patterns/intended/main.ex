defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    numbers = [1, 2, 3, 4, 5]

    evens = []

    g_counter = 0
    (fn loop ->
      if ((g_counter < numbers.length)) do
            n = Enum.at(numbers, g_counter)
        g_counter + 1
        evens = if ((rem(n, 2) == 0)), do: evens ++ [n], else: evens
        loop.()
      end
    end).()

    doubled = []

    g_counter = 0
    (fn loop ->
      if ((g_counter < numbers.length)) do
            n = Enum.at(numbers, g_counter)
        g_counter + 1
        doubled = doubled ++ [(n * 2)]
        loop.()
      end
    end).()

    Log.trace("Evens: " <> Std.string(evens), %{"fileName" => "Main.hx", "lineNumber" => 19, "className" => "Main", "methodName" => "main"})

    Log.trace("Doubled: " <> Std.string(doubled), %{"fileName" => "Main.hx", "lineNumber" => 20, "className" => "Main", "methodName" => "main"})
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
