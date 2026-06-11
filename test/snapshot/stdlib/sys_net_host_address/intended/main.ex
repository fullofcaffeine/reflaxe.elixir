defmodule Main do
  def main() do
    host = Host.new("127.0.0.1")
    if (apply(Map.get(host, :__reflaxe_class__) || Map.get(host, :__struct__), :to_string, [host]) != "127.0.0.1") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Host.toString should preserve IPv4 loopback"]
    end
    address = Address.new()
    _ = Address.set_host(address, host.ip)
    _ = Address.set_port(address, 4001)
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
