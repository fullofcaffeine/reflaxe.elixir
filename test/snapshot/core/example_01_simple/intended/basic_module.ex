defmodule BasicModule do
  @moduledoc """
    BasicModule struct generated from Haxe

     * BasicModule - Demonstrates core @:module syntax
     *
     * This example shows the most basic usage of @:module annotation
     * to eliminate boilerplate "public static" declarations while
     * maintaining Haxe's type safety.
  """

  # Module functions - generated with @:module syntax sugar

  @doc "Generated from Haxe hello"
  def hello() do
    "world"
  end


  @doc "Generated from Haxe greet"
  def greet(name) do
    "Hello, " <> name <> "!"
  end


  @doc "Generated from Haxe calculate"
  def calculate(x, y, operation) do
    temp_result = nil

    temp_result = nil

    case (operation) do
      _ -> temp_result = 0
    end

    temp_result
  end


  @doc "Generated from Haxe getTimestamp"
  def get_timestamp() do
    "2024-01-01T00:00:00Z"
  end


  @doc "Generated from Haxe isValid"
  def is_valid(input) do
    ((input != nil) && (input.length > 0))
  end


  @doc "Generated from Haxe main"
  def main() do
    Log.trace("BasicModule example compiled successfully!", %{"fileName" => "BasicModule.hx", "lineNumber" => 62, "className" => "BasicModule", "methodName" => "main"})
  end


end
