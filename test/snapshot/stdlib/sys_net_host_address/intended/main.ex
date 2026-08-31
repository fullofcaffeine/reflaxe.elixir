defmodule Main do
  def main() do
    host = Host.new("127.0.0.1")
    if (host.host != "127.0.0.1") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Host.host should preserve its input"]
    end
    if (host.ip != 2130706433) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Host.ip should use signed 32-bit IPv4 values"]
    end
    if (apply(Map.get(host, :__reflaxe_class__) || Map.get(host, :__struct__), :to_string, [host]) != "127.0.0.1") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Host.toString should preserve IPv4 loopback"]
    end
    if (String.length(apply(Map.get(host, :__reflaxe_class__) || Map.get(host, :__struct__), :reverse, [host])) == 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Host.reverse should return a local name"]
    end
    high_host = Host.new("255.255.255.255")
    if (high_host.ip != -1 or apply(Map.get(high_host, :__reflaxe_class__) || Map.get(high_host, :__struct__), :to_string, [high_host]) != "255.255.255.255") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Host should preserve the signed high IPv4 range"]
    end
    address = Address.new()
    if (Address.get_host(address) != 0 or Address.get_port(address) != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Address should start with zero host and port values"]
    end
    Address.set_host(address, host.ip)
    Address.set_port(address, 4001)
    same_address = address
    Address.set_port(same_address, 4002)
    if (Address.get_port(address) != 4002) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Address aliases should observe field changes in one process"]
    end
    cloned = apply(Map.get(address, :__reflaxe_class__) || Map.get(address, :__struct__), :clone, [address])
    if (apply(Map.get(address, :__reflaxe_class__) || Map.get(address, :__struct__), :compare, [address, cloned]) != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Address.clone should preserve host and port"]
    end
    Address.set_port(cloned, 4003)
    if (Address.get_port(address) != 4002 or apply(Map.get(address, :__reflaxe_class__) || Map.get(address, :__struct__), :compare, [address, cloned]) != 1 or apply(Map.get(cloned, :__reflaxe_class__) || Map.get(cloned, :__struct__), :compare, [cloned, address]) != -1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Address clones should have independent fields and stable port ordering"]
    end
    Address.set_host(cloned, Address.get_host(address) + 1)
    Address.set_port(cloned, Address.get_port(address))
    if (apply(Map.get(address, :__reflaxe_class__) || Map.get(address, :__struct__), :compare, [address, cloned]) != 1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Address.compare should order hosts before ports"]
    end
    reconstructed = apply(Map.get(address, :__reflaxe_class__) || Map.get(address, :__struct__), :to_host, [address])
    if (apply(Map.get(reconstructed, :__reflaxe_class__) || Map.get(reconstructed, :__struct__), :to_string, [reconstructed]) != "127.0.0.1") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Address.getHost should reconstruct Host from integer IPv4"]
    end
    local_name = Host.localhost()
    if (Kernel.is_nil(local_name) or String.length(local_name) == 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Host.localhost should return a hostname"]
    end
  end
end
