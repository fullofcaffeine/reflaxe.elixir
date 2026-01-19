defmodule Reflaxe.Exception do
  import Kernel, except: [to_string: 1], warn: false
  def new(message_param, previous_param, native_param) do
    struct = %{:message => nil, :previous => nil, :native => nil}
    struct = %{struct | message: message_param}
    struct = %{struct | previous: previous_param}
    struct = %{struct | native: native_param}
    struct
  end
  def to_string(struct) do
    struct.message
    item
  end
end
