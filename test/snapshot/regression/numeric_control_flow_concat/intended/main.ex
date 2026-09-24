defmodule Main do
  defp numeric(flag, value) do
    IO.puts("case:" <> Reflaxe.Elixir.HaxeFloat.to_string((if (value == 0), do: 7, else: 9)))
    IO.puts("if:" <> Reflaxe.Elixir.HaxeFloat.to_string((if (flag), do: 3, else: 4)))
    IO.puts("float:" <> Reflaxe.Elixir.HaxeFloat.to_string((if (flag), do: 1, else: 2.5)))
    v = "block:" <> Reflaxe.Elixir.HaxeFloat.to_string(
      (fn ->
         IO.puts("block-effect")
         _ = value + 10
       end).()
    )
    IO.puts(v)
    IO.puts(Reflaxe.Elixir.HaxeFloat.to_string((if (flag), do: 5, else: 6)) <> ":left")
    IO.puts("string:" <> (if (flag), do: "yes", else: "no"))
  end
  defp random_text(bound) do
    "random:" <> Reflaxe.Elixir.HaxeFloat.to_string(((case bound do
      std_random_max when std_random_max <= 0 -> 0
      std_random_max -> (:rand.uniform(std_random_max) - 1)
    end)))
  end
  defp prefix() do
    IO.puts("left-effect")
    "ordered:"
  end
  defp number() do
    IO.puts("right-effect")
    8
  end
  defp fail(should_throw) do
    IO.puts("throw-effect")
    if (should_throw) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "stop"]
    end
    12
  end
  def main() do
    numeric(true, 0)
    numeric(false, 1)
    v = random_text(0)
    IO.puts(v)
    v = random_text(1)
    IO.puts(v)
    v = prefix() <> Reflaxe.Elixir.HaxeFloat.to_string(number())
    IO.puts(v)
    try do
      v = prefix() <> Reflaxe.Elixir.HaxeFloat.to_string(
      (fn ->
         fail((case 1 do
           std_random_max when std_random_max <= 0 -> 0
           std_random_max -> (:rand.uniform(std_random_max) - 1)
         end) == 0)
       end).()
    )
      IO.puts(v)
      raise Reflaxe.Elixir.HaxeThrow, [value: "unreachable"]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {message, _} when is_binary(message) ->
            if (message != "stop") do
              raise Reflaxe.Elixir.HaxeThrow, [value: message]
            end
            IO.puts("caught:stop")
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
end
