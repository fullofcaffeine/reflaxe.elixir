defmodule UserService do
  @moduledoc """
    UserService module generated from Haxe

     * Module Syntax Sugar Test
     * Tests @:module annotation for simplified Elixir module generation
     * Converted from framework-based ModuleSyntaxTest.hx to snapshot test
  """

  # Module functions - generated with @:module syntax sugar

  @doc """
    Public function - should generate def syntax

  """
  @spec create_user(String.t(), integer()) :: String.t()
  def create_user(name, age) do
    name <> " is " <> Integer.to_string(age) <> " years old"
  end

  @doc """
    Private function - should generate defp syntax

  """
  @spec validate_age(integer()) :: boolean()
  def validate_age(age) do
    age >= 0 && age <= 150
  end

  @doc """
    Function with pipe operator - should preserve pipe syntax

  """
  @spec process_data(String.t()) :: String.t()
  def process_data(data) do
    data
  end

  @doc """
    Function with multiple parameters

  """
  @spec complex_function(String.t(), integer(), boolean(), Array.t()) :: String.t()
  def complex_function(arg1, arg2, arg3, arg4) do
    if (arg3), do: arg1 <> " " <> Integer.to_string(arg2), else: nil
    "default"
  end

end
