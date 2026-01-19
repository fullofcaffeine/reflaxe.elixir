defmodule CustomException do
  defexception [:message, :code]
  def new(message, code_param) do
    struct = %{:code => nil}
    struct = Map.merge(struct, Exception.new(message))
    struct = %{struct | code: code_param}
    struct
  end
end
