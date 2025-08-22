defmodule SimpleTest do
  @moduledoc """
  SimpleTest module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    map = Haxe.Ds.StringMap.new()
    map.set("test", 42)
    Log.trace("Basic map works: " <> Kernel.inspect(map.get("test")), %{"fileName" => "SimpleTest.hx", "lineNumber" => 6, "className" => "SimpleTest", "methodName" => "main"})
    Log.trace("MapTools import test complete", %{"fileName" => "SimpleTest.hx", "lineNumber" => 9, "className" => "SimpleTest", "methodName" => "main"})
  end

end
