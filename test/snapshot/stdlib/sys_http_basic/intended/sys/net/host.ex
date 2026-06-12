defmodule Host do
  import Kernel, except: [to_string: 1], warn: false
  def new(name) do
    struct = %{:__reflaxe_class__ => Host, :host => nil, :ip => nil, :host_name => nil}
    struct = %{struct | host_name: name}
    struct = %{struct | ip: resolve(name)}
    struct
  end
  def get_host(struct) do
    struct.host_name
  end
  def to_string(struct) do
    host_to_string(struct.ip)
  end
  def reverse(struct) do
    host_reverse(struct.ip)
  end
  def localhost() do
    (
            case :inet.gethostname() do
              {:ok, name} -> List.to_string(name)
              _ -> "localhost"
            end
        )
  end
  defp resolve(name) do
    (
            char_name = String.to_charlist(name)
            address =
              case :inet.parse_address(char_name) do
                {:ok, {a, b, c, d}} -> {a, b, c, d}
                {:ok, other} -> raise "sys.net.Host only supports IPv4 addresses on the Elixir target, got: #{inspect(other)}"
                {:error, _} ->
                  case :inet.getaddr(char_name, :inet) do
                    {:ok, {a, b, c, d}} -> {a, b, c, d}
                    {:ok, other} -> raise "sys.net.Host only supports IPv4 addresses on the Elixir target, got: #{inspect(other)}"
                    {:error, reason} -> raise "sys.net.Host: failed to resolve " <> inspect(name) <> ": " <> inspect(reason)
                  end
              end
            {a, b, c, d} = address
            Bitwise.bor(Bitwise.bsl(a, 24), Bitwise.bor(Bitwise.bsl(b, 16), Bitwise.bor(Bitwise.bsl(c, 8), d)))
        )
  end
  defp host_to_string(ip_param) do
    (
            {a, b, c, d} = Host.to_inet_address(ip_param)
            Enum.join([a, b, c, d], ".")
        )
  end
  defp host_reverse(ip_param) do
    (
            address = Host.to_inet_address(ip_param)
            case :inet.gethostbyaddr(address) do
              {:ok, {:hostent, name, _aliases, _addrtype, _length, _addr_list}} -> List.to_string(name)
              {:error, reason} -> raise "sys.net.Host.reverse failed for #{inspect(address)}: #{inspect(reason)}"
            end
        )
  end
  def to_inet_address(ip_param) do
    (
            value = ip_param
            {
              Bitwise.band(Bitwise.bsr(value, 24), 255),
              Bitwise.band(Bitwise.bsr(value, 16), 255),
              Bitwise.band(Bitwise.bsr(value, 8), 255),
              Bitwise.band(value, 255)
            }
        )
  end
end
