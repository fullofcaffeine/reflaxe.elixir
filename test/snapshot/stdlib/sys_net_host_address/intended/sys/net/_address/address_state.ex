defmodule AddressState do
  def create() do
    (
            ref = make_ref()
            Process.put({:reflaxe_sys_net_address, ref}, %{host: 0, port: 0})
            ref
        )
  end
  def get_host(address_ref) do
    Map.fetch!(Process.get({:reflaxe_sys_net_address, address_ref}), :host)
  end
  def set_host(address_ref, host) do
    (
            key = {:reflaxe_sys_net_address, address_ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | host: host})
            :ok
        )
  end
  def get_port(address_ref) do
    Map.fetch!(Process.get({:reflaxe_sys_net_address, address_ref}), :port)
  end
  def set_port(address_ref, port) do
    (
            key = {:reflaxe_sys_net_address, address_ref}
            state = Map.fetch!(%{value: Process.get(key)}, :value)
            Process.put(key, %{state | port: port})
            :ok
        )
  end
end
