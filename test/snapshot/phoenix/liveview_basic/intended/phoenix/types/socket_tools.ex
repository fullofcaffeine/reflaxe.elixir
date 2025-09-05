defmodule SocketTools do
  def has_assign(socket, key) do
    assigns = Assigns_Impl_.to_dynamic(Socket_Impl_.get_assigns(socket))
    Reflect.has_field(assigns, key)
  end
  def get_assign_or(socket, key, default_value) do
    assigns = Assigns_Impl_.to_dynamic(Socket_Impl_.get_assigns(socket))
    if (Reflect.has_field(assigns, key)) do
      Reflect.field(assigns, key)
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
    flash = SocketTools.get_flash(socket)
    flash != nil && Reflect.fields(flash).length > 0
  end
end