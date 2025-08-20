defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test ImportOptimizer functionality.
     * This test should generate Elixir imports for detected function usage.
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    [1, 2, 3, 4, 5]
    temp_right = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < temp_right1.length) do
          try do
            v = Enum.at(temp_right1, g)
          g = g + 1
          if (v > 2), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_right = g
    temp_right1 = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < temp_right1.length) do
          try do
            v = Enum.at(temp_right1, g)
          g = g + 1
          g ++ [v * 2]
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_right1 = g
    text = "hello world"
    Log.trace("Result: " <> Std.string(temp_right1), %{"fileName" => "Main.hx", "lineNumber" => 25, "className" => "Main", "methodName" => "main"})
    Log.trace("Text: " <> text, %{"fileName" => "Main.hx", "lineNumber" => 26, "className" => "Main", "methodName" => "main"})
    text
      |> String.trim()
      |> replace("world", "universe")
  end

end
