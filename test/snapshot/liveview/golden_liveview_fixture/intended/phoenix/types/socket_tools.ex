defmodule SocketTools do
  def has_assign(socket, key) do
    assigns = Assigns_Impl_.to_dynamic(Socket_Impl_.get_assigns(socket))
    _ = Map.has_key?(assigns, key)
  end
  def get_assign_or(socket, key, default_value) do
    assigns = Assigns_Impl_.to_dynamic(Socket_Impl_.get_assigns(socket))
    if (Map.has_key?(assigns, key)) do
      Map.get(assigns, key)
    else
      default_value
    end
  end
  def is_in_state(socket, state_name, state_value) do
    Socket_Impl_.get_assign(socket, state_name) == state_value
  end
  def get_current_user(socket) do
    Socket_Impl_.get_assign(socket, "current_user")
  end
  def get_flash(socket) do
    Socket_Impl_.get_assign(socket, "flash")
  end
  def has_flash(socket) do
    flash = get_flash(socket)
    not Kernel.is_nil(flash) and length(Reflect.fields(flash)) > 0
  end
end
