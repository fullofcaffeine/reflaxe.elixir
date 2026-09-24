defmodule ArrayConstructorControl do
  def new(seed_param) do
    struct = %{:__reflaxe_class__ => ArrayConstructorControl, :seed => nil}
    struct = %{struct | seed: seed_param}
    struct
  end
end
