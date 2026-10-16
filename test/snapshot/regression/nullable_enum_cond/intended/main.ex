defmodule Main do
  def main() do

  end
  def first() do
    {:first, "one"}
  end
  def second() do
    {:second, "two"}
  end
  def nonnullable(choice) do
    (case choice do
      {:first, _} -> true
      _ -> false
    end)
  end
  def nullable(choice) do
    cond do
      Kernel.is_nil(choice) -> false
      true ->
        (case choice do
          {:first, _} -> true
          _ -> false
        end)
    end
  end
  def payload(choice) do
    cond do
      Kernel.is_nil(choice) -> "other"
      true ->
        (case choice do
          {:first, id} -> id
          _ -> "other"
        end)
    end
  end
  def evaluated(source) do
    g = source.()
    cond do
      Kernel.is_nil(g) -> "other"
      true ->
        (case g do
          {:first, id} -> id
          _ -> "other"
        end)
    end
  end
  def reject_first(choice) do
    cond do
      Kernel.is_nil(choice) -> nil
      true ->
        (case choice do
          {:first, _} -> raise Reflaxe.Elixir.HaxeThrow, [value: "first"]
          _ -> nil
        end)
    end
    "accepted"
  end
  def guarded_field(input) do
    if (Kernel.is_nil(input.choice)) do
      false
    else
      input_choice = input.choice
      cond do
        Kernel.is_nil(input_choice) -> false
        true ->
          (case input_choice do
            {:first, _} -> true
            _ -> false
          end)
      end
    end
  end
end
