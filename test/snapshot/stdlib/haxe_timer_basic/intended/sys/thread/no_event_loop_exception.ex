defmodule NoEventLoopException do
  defexception [:message, :previous, :native, :stack]
  import Kernel, except: [to_string: 1], warn: false
  def new(msg \\ "Event loop is not available. Refer to sys.thread.Thread.runWithEventLoop.", previous_param \\ nil) do
    struct = %NoEventLoopException{}
    struct = Map.merge(struct, Map.drop(Reflaxe.Exception.new(msg, previous_param, nil), [:__struct__, :__reflaxe_class__]))
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
