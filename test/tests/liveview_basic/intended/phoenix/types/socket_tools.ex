defmodule SocketTools do
  @moduledoc """
    SocketTools module generated from Haxe

     * Socket utility functions
  """

  # Static functions
  @doc "Generated from Haxe hasAssign"
  def has_assign(socket, key) do
    assigns = Assigns_Impl_.to_dynamic(Socket_Impl_.get_assigns(socket))

    Reflect.has_field(assigns, key)
  end

  @doc "Generated from Haxe getAssignOr"
  def get_assign_or(socket, key, default_value) do
    temp_result = nil

    assigns = Assigns_Impl_.to_dynamic(Socket_Impl_.get_assigns(socket))

    temp_result = nil

    if Reflect.has_field(assigns, key), do: temp_result = Reflect.field(assigns, key), else: temp_result = default_value

    temp_result
  end

  @doc "Generated from Haxe isInState"
  def is_in_state(socket, state_name, state_value) do
    (Socket_Impl_.get_assign(socket, state_name) == state_value)
  end

  @doc "Generated from Haxe getCurrentUser"
  def get_current_user(socket) do
    Socket_Impl_.get_assign(socket, "current_user")
  end

  @doc "Generated from Haxe getFlash"
  def get_flash(socket) do
    Socket_Impl_.get_assign(socket, "flash")
  end

  @doc "Generated from Haxe hasFlash"
  def has_flash(socket) do
    flash = SocketTools.get_flash(socket)

    ((flash != nil) && (Reflect.fields(flash).length > 0))
  end

end
