defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  defp reject_unsupported_certificate_metadata(cert) do
    try do
      apply(Map.get(cert, :__reflaxe_class__) || Map.get(cert, :__struct__), :subject, [cert, "CN"])
      raise Reflaxe.Elixir.HaxeThrow, [value: "Certificate.subject should fail explicitly on the Elixir target"]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} when is_tuple(error) and elem(error, 0) in [:overflow, :outside_bounds, :custom, :blocked] ->
            (case error do
              {:custom, message} ->
                assert_that(Reflaxe.Elixir.HaxeFloat.neq(message, ""), "Certificate.subject should explain unsupported status")
              _ -> raise Reflaxe.Elixir.HaxeThrow, [value: "Certificate.subject should raise Error.Custom"]
            end)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def main() do
    cert = Certificate.load_defaults()
    reject_unsupported_certificate_metadata(cert)
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
