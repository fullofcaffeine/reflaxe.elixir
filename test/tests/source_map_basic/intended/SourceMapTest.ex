defmodule SourceMapTest do
  @moduledoc "SourceMapTest module generated from Haxe"

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    test = SourceMapTest.new()
    result = test.simpleMethod()
    condition = test.conditionalMethod(42)
    Log.trace("Source mapping test: " <> result <> " " <> Std.string(condition), %{"fileName" => "SourceMapTest.hx", "lineNumber" => 23, "className" => "SourceMapTest", "methodName" => "main"})
  end

  # Instance functions
  @doc "Function simple_method"
  @spec simple_method() :: String.t()
  def simple_method() do
    "test"
  end

  @doc "Function conditional_method"
  @spec conditional_method(integer()) :: boolean()
  def conditional_method(value) do
    if (value > 0), do: true, else: false
  end

end
