defmodule InstanceScope do
  def new(amount_param) do
    struct = %{:__reflaxe_class__ => InstanceScope, :amount => nil}
    struct = %{struct | amount: amount_param}
    struct
  end
  def value(struct) do
    local_value(struct)
  end
  defp local_value(struct) do
    struct.amount
  end
end
