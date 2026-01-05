defmodule CustomError do
  def new(message_param) do
    struct = %{:message => nil}
    struct = %{struct | message: message_param}
    struct
  end
end
