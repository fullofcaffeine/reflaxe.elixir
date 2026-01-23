defmodule CustomException do
  defexception [:message, :previous, :native, :stack, :code]
  def new(message, code_param) do
    struct = %CustomException{}
    struct = Map.merge(struct, Map.delete(Reflaxe.Exception.new(message), :__struct__))
    struct = %{struct | code: code_param}
    struct
  end
end
