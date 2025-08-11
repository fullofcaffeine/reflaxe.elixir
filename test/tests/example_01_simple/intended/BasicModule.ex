defmodule BasicModule do
  @moduledoc """
  BasicModule - Demonstrates core @:module syntax
  
  This example shows the most basic usage of @:module annotation
  to eliminate boilerplate "public static" declarations while
  maintaining Haxe's type safety.
  """

  @doc """
  Simple greeting function
  """
  def hello do
    "world"
  end

  @doc """
  Function with parameters
  """
  def greet(name) do
    "Hello, #{name}!"
  end

  @doc """
  Function with multiple parameters and logic
  Demonstrates that complex logic compiles correctly
  """
  def calculate(x, y, operation) do
    case operation do
      "add" -> x + y
      "subtract" -> x - y
      "multiply" -> x * y
      "divide" when y != 0 -> div(x, y)
      "divide" -> 0
      _ -> 0
    end
  end

  @doc """
  Function with no parameters
  """
  def get_timestamp do
    "2024-01-01T00:00:00Z"
  end

  @doc """
  Boolean function demonstrating predicate patterns
  Common in Elixir for validation and guards
  """
  def is_valid(input) do
    input != nil and String.length(input) > 0
  end
end