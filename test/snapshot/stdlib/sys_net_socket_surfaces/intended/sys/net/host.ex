defmodule Host do
  import Kernel, except: [to_string: 1], warn: false
  def new(name) do
    struct = %{:__reflaxe_class__ => Host, :host => nil, :ip => nil}
    struct = %{struct | host: name}
    struct = %{struct | ip: resolve(name)}
    struct
  end
  def to_string(struct) do
    address = to_inet_address(struct.ip)
    "#{Integer.to_string(elem(address, 0))}.#{Integer.to_string(elem(address, 1))}.#{Integer.to_string(elem(address, 2))}.#{Integer.to_string(elem(address, 3))}"
  end
  def reverse(struct) do
    result = :inet.gethostbyaddr(to_inet_address(struct.ip))
    if (elem(result, 0) != :ok) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "sys.net.Host.reverse failed for " <> apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :to_string, [struct])]
    end
    entry = elem(result, 1)
    List.to_string(elem(entry, 1))
  end
  def localhost() do
    result = :inet.gethostname()
    if (elem(result, 0) != :ok) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "sys.net.Host.localhost failed"]
    end
    List.to_string(elem(result, 1))
  end
  defp resolve(name) do
    result = :inet.getaddr(String.to_charlist(name), :inet)
    if (elem(result, 0) != :ok) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "sys.net.Host: failed to resolve " <> name]
    end
    address = elem(result, 1)
    signed_high_byte = if (elem(address, 0) >= 128), do: (elem(address, 0) - 256), else: elem(address, 0)
    Bitwise.bor(Bitwise.bor(Bitwise.bor(Bitwise.bsl(signed_high_byte, 24), Bitwise.bsl(elem(address, 1), 16)), Bitwise.bsl(elem(address, 2), 8)), elem(address, 3))
  end
  def to_inet_address(ip_param) do
    {Bitwise.band(Bitwise.bsr(ip_param, 24), 255), Bitwise.band(Bitwise.bsr(ip_param, 16), 255), Bitwise.band(Bitwise.bsr(ip_param, 8), 255), Bitwise.band(ip_param, 255)}
  end
end
