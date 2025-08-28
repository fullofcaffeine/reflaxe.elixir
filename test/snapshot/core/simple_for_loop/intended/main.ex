defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    fruits = ["apple", "banana", "orange"]

    g_counter = 0

    (fn loop ->
      if ((g_counter < fruits.length)) do
            fruit = Enum.at(fruits, g_counter)
        g_counter + 1
        Log.trace("For: " <> fruit, %{"fileName" => "Main.hx", "lineNumber" => 10, "className" => "Main", "methodName" => "main"})
        loop.()
      end
    end).()

    i = 0

    (fn loop ->
      if ((i < fruits.length)) do
            Log.trace("While: " <> Enum.at(fruits, i), %{"fileName" => "Main.hx", "lineNumber" => 16, "className" => "Main", "methodName" => "main"})
        i + 1
        loop.()
      end
    end).()
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
