defmodule SourceMapTest do
  @moduledoc """
  SourceMapTest module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  test = SourceMapTest.new()
  result = test.simple_method()
  condition = test.conditional_method(42)
  Log.trace("Source mapping test: " + result + " " + Std.string(condition), %{fileName: "SourceMapTest.hx", lineNumber: 23, className: "SourceMapTest", methodName: "main"})
)
  end

  # Instance functions
  @doc "Function simple_method"
  @spec simple_method() :: TInst(String,[]).t()
  def simple_method() do
    "test"
  end

  @doc "Function conditional_method"
  @spec conditional_method(TAbstract(Int,[]).t()) :: TAbstract(Bool,[]).t()
  def conditional_method(arg0) do
    if (value > 0), do: true, else: false
  end

end
