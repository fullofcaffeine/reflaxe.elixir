defmodule Reflaxe.Exception do
  defexception [:message, :previous, :native, :stack]
  import Kernel, except: [to_string: 1], warn: false
  def new(message_param, previous \\ nil, native \\ nil) do
    struct = %Reflaxe.Exception{}
    struct = %{ struct | message: message_param }
    struct = %{ struct | previous: previous }
    struct = %{ struct | native: native }
    struct = %{ struct | stack: apply(CallStack_Impl_, :call_stack, []) }
    struct
  end
  def get_message(struct) do
    Map.get(struct, :message)
  end
  def to_string(struct) do
    get_message(struct)
  end
end
