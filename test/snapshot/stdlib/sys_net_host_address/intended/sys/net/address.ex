defmodule Address do
  def new() do
    struct = %{:__reflaxe_class__ => Address, :host => nil, :port => nil, :address_ref => nil}
    struct = %{struct | address_ref: AddressState.create()}
    set_host(struct, 0)
    set_port(struct, 0)
    struct
  end
  def get_host(struct) do
    AddressState.get_host(struct.address_ref)
  end
  def set_host(struct, value) do
    AddressState.set_host(struct.address_ref, value)
    value
  end
  def get_port(struct) do
    AddressState.get_port(struct.address_ref)
  end
  def set_port(struct, value) do
    AddressState.set_port(struct.address_ref, value)
    value
  end
  def to_host(struct) do
    host_object = Host.new("127.0.0.1")
    host_object = %{host_object | ip: get_host(struct)}
    host_object
  end
  def compare(struct, a) do
    host_delta = (get_host(a) - get_host(struct))
    if (host_delta != 0) do
      host_delta
    else
      port_delta = (get_port(a) - get_port(struct))
      if (port_delta != 0), do: port_delta, else: 0
    end
  end
  def clone(struct) do
    cloned = Address.new()
    set_host(cloned, get_host(struct))
    set_port(cloned, get_port(struct))
    cloned
  end
end
