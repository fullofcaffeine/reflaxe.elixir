defmodule Vehicle do
  def new() do
    struct = %{:__reflaxe_class__ => Vehicle, :speed => nil}
    struct = %{struct | speed: 0}
    struct
  end
  def accelerate(_struct) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Abstract method"]
  end
end
