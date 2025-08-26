defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    i = 0
    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> ((i < 5)) end,
        fn ->
          i + 1
        end,
        loop_helper
      )
    )
    j = 0
    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> ((j < 3)) end,
        fn ->
          j + 1
        end,
        loop_helper
      )
    )
    counter = 10
    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> ((counter > 0)) end,
        fn ->
          (
                counter = counter - 2
                if ((counter == 4)) do
                throw(:break)
              end
              )
        end,
        loop_helper
      )
    )
    k = 0
    evens = []
    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> ((k < 10)) end,
        fn ->
          (
                k + 1
                if ((rem(k, 2) != 0)) do
                throw(:continue)
              end
                evens ++ [k]
              )
        end,
        loop_helper
      )
    )
    count = 0
    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> true end,
        fn ->
          (
                count + 1
                if ((count == 10)) do
                throw(:break)
              end
              )
        end,
        loop_helper
      )
    )
    outer = 0
    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> ((outer < 3)) end,
        fn ->
          (
                inner = 0
                (
            # Simple module-level pattern (inline for now)
            loop_helper = fn condition_fn, body_fn, loop_fn ->
              if condition_fn.() do
                body_fn.()
                loop_fn.(condition_fn, body_fn, loop_fn)
              else
                nil
              end
            end

            loop_helper.(
              fn -> ((inner < 2)) end,
              fn ->
                (
                      Log.trace("Nested: " <> to_string(outer) <> ", " <> to_string(inner), %{"fileName" => "Main.hx", "lineNumber" => 47, "className" => "Main", "methodName" => "main"})
                      inner + 1
                    )
              end,
              loop_helper
            )
          )
                outer + 1
              )
        end,
        loop_helper
      )
    )
    a = 0
    b = 10
    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> (((a < 5) && (b > 5))) end,
        fn ->
          (
                a + 1
                b - 1
              )
        end,
        loop_helper
      )
    )
    x = 0
    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> ((x < 10)) end,
        fn ->
          (
                x + 1
                if ((x == 5)) do
                throw(:break)
              end
              )
        end,
        loop_helper
      )
    )
    Log.trace("Final i: " <> to_string(i), %{"fileName" => "Main.hx", "lineNumber" => 68, "className" => "Main", "methodName" => "main"})
    Log.trace("Final j: " <> to_string(j), %{"fileName" => "Main.hx", "lineNumber" => 69, "className" => "Main", "methodName" => "main"})
    Log.trace("Final counter: " <> to_string(counter), %{"fileName" => "Main.hx", "lineNumber" => 70, "className" => "Main", "methodName" => "main"})
    Log.trace("Evens: " <> Std.string(evens), %{"fileName" => "Main.hx", "lineNumber" => 71, "className" => "Main", "methodName" => "main"})
    Log.trace("Count from infinite: " <> to_string(count), %{"fileName" => "Main.hx", "lineNumber" => 72, "className" => "Main", "methodName" => "main"})
    Log.trace("Complex condition result: a=" <> to_string(a) <> ", b=" <> to_string(b), %{"fileName" => "Main.hx", "lineNumber" => 73, "className" => "Main", "methodName" => "main"})
    Log.trace("Do-while with break: x=" <> to_string(x), %{"fileName" => "Main.hx", "lineNumber" => 74, "className" => "Main", "methodName" => "main"})
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
