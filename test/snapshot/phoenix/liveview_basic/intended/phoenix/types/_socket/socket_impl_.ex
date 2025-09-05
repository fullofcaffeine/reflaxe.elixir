defmodule Socket_Impl_ do
  def from_dynamic(socket) do
    socket
  end
  def to_dynamic(this1) do
    this1
  end
  def get_assigns(this1) do
    Assigns_Impl_.from_dynamic(Reflect.field(this1, "assigns"))
  end
  def get_assign(this1, key) do
    assigns = Reflect.field(this1, "assigns")
    Reflect.field(assigns, key)
  end
  def is_connected(this1) do
    Reflect.field(this1, "connected")
  end
  def get_id(this1) do
    Reflect.field(this1, "id")
  end
  def get_transport(this1) do
    transport = Reflect.field(this1, "transport")
    :WebSocket
  end
  def get_endpoint(this1) do
    Reflect.field(this1, "endpoint")
  end
  def get_router(this1) do
    Reflect.field(this1, "router")
  end
  def get_view(this1) do
    Reflect.field(this1, "view")
  end
  def get_changed(this1) do
    Reflect.field(this1, "changed")
  end
  def has_changed(this1, key) do
    changed = Socket_Impl_.get_changed(this1)
    Reflect.has_field(changed, key)
  end
  def get_parent_pid(this1) do
    Reflect.field(this1, "parent_pid")
  end
  def get_root_pid(this1) do
    Reflect.field(this1, "root_pid")
  end
  def get_transport_pid(this1) do
    Reflect.field(this1, "transport_pid")
  end
end