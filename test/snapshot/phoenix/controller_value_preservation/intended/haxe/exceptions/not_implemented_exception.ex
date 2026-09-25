defmodule NotImplementedException do
  defexception [:message, :previous, :native, :stack]
  def new(message_param, previous_param, pos) do
    message = if Kernel.is_nil(message_param), do: "Not implemented", else: message_param
    struct = %__MODULE__{}
    struct = Map.merge(struct, Map.drop(PosException.new(message, previous_param, pos), [:__struct__, :__reflaxe_class__]))
    struct
  end
  def to_string(struct) do
    PosException.to_string(struct)
  end
end
