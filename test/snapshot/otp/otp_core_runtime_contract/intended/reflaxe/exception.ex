defmodule Reflaxe.Exception do
  defexception [:message, :previous, :native, :stack]
  def new(message, previous, native) do
    struct = %Reflaxe.Exception{}
    struct = %{ struct | message: message }
    struct = %{ struct | previous: previous }
    struct = %{ struct | native: native }
    struct = %{ struct | stack: apply(CallStack_Impl_, :call_stack, []) }
    struct
  end
end
