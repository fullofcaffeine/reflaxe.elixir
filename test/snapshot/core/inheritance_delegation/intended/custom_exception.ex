defmodule CustomException do
  defexception [:message, :previous, :native, :stack]
  import Kernel, except: [to_string: 1], warn: false
  def new(message) do
    struct = %CustomException{}
    struct = Map.merge(struct, Map.delete(Reflaxe.Exception.new(message), :__struct__))
    struct
  end
  def to_string(struct) do
    "CustomException: #{Reflaxe.Exception.get_message(struct)}"
  end
end
