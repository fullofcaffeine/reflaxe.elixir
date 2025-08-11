defmodule UserService do
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
  @spec create_user(TInst(String,[]).t(), TAbstract(Int,[]).t()) :: TInst(String,[]).t()
  def create_user(name, age) do
    # TODO: Implement function body
    nil
  end

  @doc "
     * Private function - should generate defp syntax
     "
  @spec validate_age(TAbstract(Int,[]).t()) :: TAbstract(Bool,[]).t()
  def validate_age(age) do
    # TODO: Implement function body
    nil
  end

  @doc "
     * Function with pipe operator - should preserve pipe syntax
     "
  @spec process_data(TInst(String,[]).t()) :: TInst(String,[]).t()
  def process_data(data) do
    # TODO: Implement function body
    nil
  end

  @doc "
     * Function with multiple parameters
     "
  @spec complex_function(TInst(String,[]).t(), TAbstract(Int,[]).t(), TAbstract(Bool,[]).t(), TInst(Array,[TInst(String,[])]).t()) :: TInst(String,[]).t()
  def complex_function(arg1, arg2, arg3, arg4) do
    # TODO: Implement function body
    nil
  end

end


defmodule StringUtils do
  @moduledoc """
  StringUtils module generated from Haxe
  
  
 * Second module to test multiple module generation
 
  """

  # Module functions - generated with @:module syntax sugar

  @doc "Function is_empty"
  @spec is_empty(TInst(String,[]).t()) :: TAbstract(Bool,[]).t()
  def is_empty(str) do
    # TODO: Implement function body
    nil
  end

  @doc "Function sanitize"
  @spec sanitize(TInst(String,[]).t()) :: TInst(String,[]).t()
  def sanitize(str) do
    # TODO: Implement function body
    nil
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
  @spec format_name(TInst(String,[]).t(), TInst(String,[]).t()) :: TInst(String,[]).t()
  def format_name(first_name, last_name) do
    # TODO: Implement function body
    nil
  end

end
