defmodule TestClass do
  @moduledoc """
    TestClass struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:name]

  @type t() :: %__MODULE__{
    name: String.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(String.t()) :: t()
  def new(arg0) do
    %__MODULE__{
      name: arg0
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc "Generated from Haxe doSomething"
  def do_something(%__MODULE__{} = struct) do
    Log.trace("TestClass doing something with: " <> struct.name, %{"fileName" => "SourceMapValidationTest.hx", "lineNumber" => 73, "className" => "TestClass", "methodName" => "doSomething"})
  end

end
