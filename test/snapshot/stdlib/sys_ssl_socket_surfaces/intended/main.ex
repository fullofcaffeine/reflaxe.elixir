defmodule Main do
  def main() do
    cert = Certificate.load_defaults()
    socket = SslSocket.new()
    socket = %{socket | verify_cert: false}
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :set_timeout, [socket, 0.01])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :set_blocking, [socket, false])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :set_hostname, [socket, "localhost"])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :set_ca, [socket, cert])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :bind, [socket, Host.new("127.0.0.1"), 0])
    apply(Map.get(socket, :__reflaxe_class__) || Map.get(socket, :__struct__), :close, [socket])
  end
end
