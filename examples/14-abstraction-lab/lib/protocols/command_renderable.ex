defmodule AbstractionLab.CommandRenderable do
  def render_command(_, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Protocol method should be implemented"]
  end
  def render_summary(_, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Protocol method should be implemented"]
  end
end
