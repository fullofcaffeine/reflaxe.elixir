defmodule NativeResultCases do
  def new() do
    %{:__reflaxe_class__ => NativeResultCases}
  end
  def void_result(_struct) do

  end
  def raise_only(_struct) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "intentional"]
  end
  def branch_value(_struct, flag) do
    if (flag), do: 3, else: 4
  end
  def case_value(_struct, code) do
    (case code do
      1 -> "one"
      2 -> "two"
      _ -> "other"
    end)
  end
  def nullable_string(_struct, flag) do
    if (flag), do: "value", else: nil
  end
  def loop_carrier(_struct, values) do
    _g = 0
    (case Enum.reduce_while(values, :__reflaxe_no_return__, fn value, _ ->
      if (value > 2), do: {:halt, {:__reflaxe_return__, value}}, else: {:cont, :__reflaxe_no_return__}
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      _ -> -1
    end)
  end
  def callback_value(_struct, input) do
    input + 1
  end
end
