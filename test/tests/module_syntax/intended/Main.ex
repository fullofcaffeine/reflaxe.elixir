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


defmodule StringUtils do
  @moduledoc """
    StringUtils module generated from Haxe

     * Second module to test multiple module generation
  """

  # Module functions - generated with @:module syntax sugar

  @doc "Function is_empty"
  @spec is_empty(String.t()) :: boolean()
  def is_empty(str) do
    str == nil || String.length(str) == 0
  end

  @doc "Function sanitize"
  @spec sanitize(String.t()) :: String.t()
  def sanitize(str) do
    str
  end

end


defmodule UserHelper do
  @moduledoc """
    UserHelper module generated from Haxe

     * Module with edge case: special characters in name
     * Should be sanitized to valid Elixir module name
  """

  # Module functions - generated with @:module syntax sugar

  @doc "Function format_name"
  @spec format_name(String.t(), String.t()) :: String.t()
  def format_name(first_name, last_name) do
    first_name <> " " <> last_name
  end

end
