defmodule Reflaxe.Exception do
  defexception [:message, :previous, :native, :stack]
  import Kernel, except: [to_string: 1], warn: false
  def new(message_param, previous_param, native_param) do
    struct = %Reflaxe.Exception{}
    struct = %{ struct | message: message_param }
    struct = %{ struct | previous: previous_param }
    struct = %{ struct | native: native_param }
    struct = %{ struct | stack: [] }
    struct
  end
  def get_message(struct) do
    Map.get(struct, :message)
    item
  end
  def get_stack(struct) do
    Map.get(struct, :stack, [])
    item
  end
  def get_previous(struct) do
    Map.get(struct, :previous)
    item
  end
  def get_native(struct) do
    Map.get(struct, :native)
    item
  end
  def to_string(struct) do
    get_message(struct)
    item
  end
  def details(struct) do
    
build = fn build, ex, acc ->
  if Kernel.is_nil(ex) do
    acc
  else
    msg = Kernel.to_string(Map.get(ex, :message))
    prev = Map.get(ex, :previous)
    acc = if acc == "", do: msg, else: acc <> "\nCaused by: " <> msg
    build.(build, prev, acc)
  end
end
build.(build, struct, "")

    item
  end
end
