defmodule AbstractionLab.CommandRenderable do
  def render_command(_struct, _value) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Protocol method should be implemented"]
  end
  def render_summary(_struct, _value) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Protocol method should be implemented"]
  end
end
