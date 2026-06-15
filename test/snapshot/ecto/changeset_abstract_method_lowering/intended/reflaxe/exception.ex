defmodule Reflaxe.Exception do
  defexception [:message, :previous, :native, :stack]
  import Kernel, except: [to_string: 1], warn: false
  def new(message_param, previous_param, native_param) do
    struct = %Reflaxe.Exception{}
    struct = %{ struct | message: message_param }
    struct = %{ struct | previous: previous_param }
    struct = %{ struct | native: native_param }
    struct = %{ struct | stack: apply(CallStack_Impl_, :call_stack, []) }
    struct
  end
  def get_message(struct) do
    Map.get(struct, :message)
  end
  def get_stack(struct) do
    Map.get(struct, :stack, [])
  end
  def get_previous(struct) do
    Map.get(struct, :previous)
  end
  def get_native(struct) do
    Map.get(struct, :native)
  end
  def to_string(struct) do
    get_message(struct)
  end
  def details(struct) do
    
build = fn build, ex, acc ->
  if Kernel.is_nil(ex) do
    acc
  else
    msg = Kernel.to_string(Map.get(ex, :message))
    stack = Map.get(ex, :stack, [])
    stack_text = apply(CallStack_Impl_, :to_string, [stack])
    prev = Map.get(ex, :previous)
    entry = msg <> stack_text
    acc = if acc == "", do: entry, else: acc <> "\nCaused by: " <> entry
    build.(build, prev, acc)
  end
end
build.(build, struct, "")

  end
end
