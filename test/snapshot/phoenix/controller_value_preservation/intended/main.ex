defmodule Main do
  def main() do
    if (ProbeWeb.ValueController.rebind(3) != 10) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "controller preparation was lost"]
    end
    if (ProbeWeb.ValueController.nested(40, {:accepted, 5}) != 52) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "outer value was replaced"]
    end
    if (ProbeWeb.ValueController.nested(40, {:denied}) != -1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "denial changed"]
    end
    if (ProbeWeb.ValueController.nested(-1, {:accepted, 5}) != -2) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "nested denial changed"]
    end
    if (ProbeWeb.ValueController.nested(40, {:accepted, -1}) != -3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "caught exception changed"]
    end
    if (ProbeWeb.ValueController.ignored({:accepted, 9}, 70) != 70) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "ignored payload shadowed outer value"]
    end
    if (ProbeWeb.ValueController.nested_ignored({:accepted, 70}, {:accepted, 9}) != 70) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "nested ignored payload shadowed outer binder"]
    end
    if (PlainValues.nested_ignored({:accepted, 70}, {:accepted, 9}) != 70) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "plain nested ignored payload shadowed outer binder"]
    end
    if (ProbeWeb.ValueController.aliases(3, 4, 10) != 27) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "adjacent aliases were deleted"]
    end
    if (ProbeWeb.ValueController.nested_ok({:ok, 70}, {:ok, 9}) != 70) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "ignored Ok payload shadowed outer value"]
    end
    if (ProbeWeb.ValueController.nested_error({:error, 70}, {:error, 9}) != 70) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "ignored Error payload shadowed outer reason"]
    end
    if (ProbeWeb.ValueController.cross_receiver({:ok, 5}, {:ok, 9}) != 79) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "nested receiver made an ignored outer payload live"]
    end
  end
end
