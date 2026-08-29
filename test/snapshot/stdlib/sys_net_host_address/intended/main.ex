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
    Address.set_host(address, host.ip)
    Address.set_port(address, 4001)
    cloned = apply(Map.get(address, :__reflaxe_class__) || Map.get(address, :__struct__), :clone, [address])
    if (apply(Map.get(address, :__reflaxe_class__) || Map.get(address, :__struct__), :compare, [address, cloned]) != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Address.clone should preserve host and port"]
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
