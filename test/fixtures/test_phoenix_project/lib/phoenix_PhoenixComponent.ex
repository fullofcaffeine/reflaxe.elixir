defmodule PhoenixComponent do
  use Bitwise
  @moduledoc """
  PhoenixComponent module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("Phoenix integration working!", %{fileName => "src_haxe/phoenix/PhoenixComponent.hx", lineNumber => 5, className => "phoenix.PhoenixComponent", methodName => "main"})
  end

  @doc "Function render"
  @spec render() :: String.t()
  def render() do
    "<div>Hello from Haxe component!</div>"
  end

end
