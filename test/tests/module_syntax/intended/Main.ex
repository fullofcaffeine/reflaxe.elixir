defmodule UserService do
  use Bitwise
  @moduledoc """
  UserService module generated from Haxe
  
  
 * Module Syntax Sugar Test
 * Tests @:module annotation for simplified Elixir module generation
 * Converted from framework-based ModuleSyntaxTest.hx to snapshot test
 
  """

  # Module functions - generated with @:module syntax sugar

  @doc "
     * Public function - should generate def syntax
     "
  @spec create_user(String.t(), integer()) :: String.t()
  def create_user(name, age) do
    # TODO: Implement function body
    nil
  end

  @doc "
     * Private function - should generate defp syntax
     "
  @spec validate_age(integer()) :: boolean()
  def validate_age(age) do
    # TODO: Implement function body
    nil
  end

  @doc "
     * Function with pipe operator - should preserve pipe syntax
     "
  @spec process_data(String.t()) :: String.t()
  def process_data(data) do
    # TODO: Implement function body
    nil
  end

  @doc "
     * Function with multiple parameters
     "
  @spec complex_function(String.t(), integer(), boolean(), Array.t()) :: String.t()
  def complex_function(arg1, arg2, arg3, arg4) do
    # TODO: Implement function body
    nil
  end

end


defmodule StringUtils do
  use Bitwise
  @moduledoc """
  StringUtils module generated from Haxe
  
  
 * Second module to test multiple module generation
 
  """

  # Module functions - generated with @:module syntax sugar

  @doc "Function is_empty"
  @spec is_empty(String.t()) :: boolean()
  def is_empty(str) do
    # TODO: Implement function body
    nil
  end

  @doc "Function sanitize"
  @spec sanitize(String.t()) :: String.t()
  def sanitize(str) do
    # TODO: Implement function body
    nil
  end

end


defmodule UserHelper do
  use Bitwise
  @moduledoc """
  UserHelper module generated from Haxe
  
  
 * Module with edge case: special characters in name
 * Should be sanitized to valid Elixir module name
 
  """

  # Module functions - generated with @:module syntax sugar

  @doc "Function format_name"
  @spec format_name(String.t(), String.t()) :: String.t()
  def format_name(first_name, last_name) do
    # TODO: Implement function body
    nil
  end

end
