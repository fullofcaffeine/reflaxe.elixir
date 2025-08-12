defmodule TestModule do
  @moduledoc """
  TestModule module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    Log.trace("Hello from integrated Mix compilation!", %{fileName: "src_haxe/test/integration/TestModule.hx", lineNumber: 5, className: "test.integration.TestModule", methodName: "main"})
  end

  @doc "Function get_message"
  @spec get_message() :: TInst(String,[]).t()
  def get_message() do
    "Mix integration successful!"
  end

end
