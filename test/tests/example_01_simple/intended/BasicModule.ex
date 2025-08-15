defmodule BasicModule do
  use Bitwise
  @moduledoc """
  BasicModule module generated from Haxe
  
  
 * BasicModule - Demonstrates core @:module syntax
 * 
 * This example shows the most basic usage of @:module annotation
 * to eliminate boilerplate "public static" declarations while
 * maintaining Haxe's type safety.
 
  """

  # Module functions - generated with @:module syntax sugar

  @doc """
    Simple greeting function
    Compiles to: def hello(), do: "world"
  """
  @spec hello() :: String.t()
  def hello() do
    "world"
  end

  @doc """
    Function with parameters
    Compiles to: def greet(name), do: "Hello, #{name}!"
  """
  @spec greet(String.t()) :: String.t()
  def greet(name) do
    "Hello, " <> name <> "!"
  end

  @doc """
    Function with multiple parameters and logic
    Demonstrates that complex logic compiles correctly
  """
  @spec calculate(integer(), integer(), String.t()) :: integer()
  def calculate(x, y, operation) do
    temp_result = nil
    case (operation) do
      "add" ->
        temp_result = x + y
      "divide" ->
        if (y != 0), do: temp_result = Std.int(x / y), else: temp_result = 0
      "multiply" ->
        temp_result = x * y
      "subtract" ->
        temp_result = x - y
      _ ->
        temp_result = 0
    end
    temp_result
  end

  @doc """
    Function with no parameters
    Compiles to: def get_timestamp(), do: DateTime.utc_now()
  """
  @spec get_timestamp() :: String.t()
  def get_timestamp() do
    "2024-01-01T00:00:00Z"
  end

  @doc """
    Boolean function demonstrating predicate patterns
    Common in Elixir for validation and guards
  """
  @spec is_valid(String.t()) :: boolean()
  def is_valid(input) do
    input != nil && String.length(input) > 0
  end

  @doc """
    Main function for compilation testing

  """
  @spec main() :: nil
  def main() do
    Log.trace("BasicModule example compiled successfully!", %{fileName => "BasicModule.hx", lineNumber => 62, className => "BasicModule", methodName => "main"})
  end

end
