defmodule ProbeAppWeb do
  defmacro __using__(:channel) do
    quote do
      use Phoenix.Channel
    end
  end
  defmacro __using__(:controller) do
    quote do
      use Phoenix.Controller, formats: [:json]
    end
  end
end
[output] = System.argv()
files = Path.wildcard(Path.join(output, "**/*.ex"))
case Kernel.ParallelCompiler.compile(files, warnings_as_errors: true) do
  {:ok, _, []} -> :ok
  other -> raise "strict generated compile failed: #{inspect(other)}"
end
socket = %Phoenix.Socket{}
result = ProbeAppWeb.ProbeChannel.nested(socket, {:granted, "opaque-reference"})
if result.assigns != %{fixed: "opaque-reference", other: "second"}, do: raise("wrong assignments")
if ProbeAppWeb.ProbeChannel.direct(socket).assigns != %{fixed: "plain"}, do: raise("wrong direct assignment")
if ProbeAppWeb.ProbeController.halted(Plug.Conn.halt(Plug.Test.conn(:get, "/"))) != true, do: raise("halt lost")
if ProbeAppWeb.ProbeController.decode(%{fixed: 7}) != 7, do: raise("decode failed")
if ProbeAppWeb.ProbeController.helper(3) != 19, do: raise("same-named helper redirected")
if PlainRemoteCalls.nested(socket, {:granted, "plain-reference"}).assigns != %{fixed: "plain-reference"}, do: raise("plain-module target redirected")
if ProbeAppWeb.ProbeChannel.nested(socket, {:denied}) != socket, do: raise("denied branch changed")
IO.puts("typed remote calls preserved")
