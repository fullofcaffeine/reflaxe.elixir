defmodule SourceMapTest do
  @moduledoc """
    SourceMapTest struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    test = SourceMapTest.new()

    result = test.simple_method()

    condition = test.conditional_method(42)

    Log.trace("Source mapping test: " <> result <> " " <> Std.string(condition), %{"fileName" => "SourceMapTest.hx", "lineNumber" => 23, "className" => "SourceMapTest", "methodName" => "main"})
  end

  # Instance functions
  @doc "Generated from Haxe simpleMethod"
  def simple_method(%__MODULE__{} = struct) do
    "test"
  end

  @doc "Generated from Haxe conditionalMethod"
  def conditional_method(%__MODULE__{} = struct, value) do
    if ((value > 0)) do
      true
    else
      false
    end
  end

end
