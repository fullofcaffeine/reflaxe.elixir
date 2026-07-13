defmodule AbstractionLab.IntCommandRenderable do
  def new() do
    %{:__reflaxe_class__ => AbstractionLab.IntCommandRenderable}
  end
  def render_command(_struct, value) do
    "retry:#{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
  def render_summary(_struct, value) do
    "retry attempt ##{Reflaxe.Elixir.HaxeFloat.to_string(value)}"
  end
end
