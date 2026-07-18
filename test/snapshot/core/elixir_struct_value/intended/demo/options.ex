defmodule Demo.Options do
  defstruct [:count, :enabled?, :name]
  def new(name_param, count_param \\ 0, enabled \\ true) do
    struct = %Demo.Options{}
    struct = %{struct | name: name_param}
    struct = %{struct | count: count_param}
    struct = %{struct | enabled?: enabled}
    struct
  end
end
