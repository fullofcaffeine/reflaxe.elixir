defmodule CustomException do
  defexception [:message, :previous, :native, :stack]
  import Kernel, except: [to_string: 1], warn: false
  def new(message_param) do
    struct = %CustomException{}
    struct = Map.merge(struct, Map.delete(Reflaxe.Exception.new(message_param, nil, nil), :__struct__))
    struct
  end
  def to_string(struct) do
    "CustomException: #{Reflaxe.Exception.get_message(struct)}"
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
  def details(struct) do
    Reflaxe.Exception.details(struct)
  end
end
