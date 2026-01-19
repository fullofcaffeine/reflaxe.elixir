defmodule CustomException do
  defexception [:message]
  import Kernel, except: [to_string: 1], warn: false
  def new(message) do
    struct = %{}
    struct = Map.merge(struct, Exception.new(message))
    struct
  end
  def to_string(struct) do
    "CustomException: #{Exception.get_message(struct)}"
  end
end
