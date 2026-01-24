defmodule CustomError do
  def new(message_param) do
    struct = %{:__reflaxe_class__ => CustomError, :message => nil}
    struct = %{struct | message: message_param}
    struct
  end
end
