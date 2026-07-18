defmodule ThreadPoolException do
  defexception [:message, :previous, :native, :stack]
  import Kernel, except: [to_string: 1], warn: false
  def new(message_param, previous_param \\ nil, native_param \\ nil) do
    struct = %ThreadPoolException{}
    struct = Map.merge(struct, Map.drop(Reflaxe.Exception.new(message_param, previous_param, native_param), [:__struct__, :__reflaxe_class__]))
    struct
  end
  def get_message(struct) do
    Reflaxe.Exception.get_message(struct)
  end
  def get_stack(struct) do
    Reflaxe.Exception.get_stack(struct)
  end
  def get_previous(struct) do
    Reflaxe.Exception.get_previous(struct)
  end
  def get_native(struct) do
    Reflaxe.Exception.get_native(struct)
  end
  def to_string(struct) do
    Reflaxe.Exception.to_string(struct)
  end
  def details(struct) do
    Reflaxe.Exception.details(struct)
  end
end
