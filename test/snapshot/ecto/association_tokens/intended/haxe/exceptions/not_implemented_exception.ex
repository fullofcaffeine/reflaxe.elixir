defmodule NotImplementedException do
  defexception [:message, :previous, :native, :stack, :pos_infos]
  import Kernel, except: [to_string: 1], warn: false
  def new(message_param, previous_param, pos) do
    struct = %NotImplementedException{}
    struct = Map.merge(struct, Map.drop(PosException.new(message_param, previous_param, pos), [:__struct__, :__reflaxe_class__]))
    struct
  end
  def to_string(struct) do
    PosException.to_string(struct)
  end
end
