defmodule LimitedController do
  use Bitwise
  @moduledoc """
  LimitedController module generated from Haxe
  
  
 * Valid controller class with limited methods for testing RouterBuildMacro action validation
 
  """

  # Static functions
  @doc "Function index"
  @spec index() :: String.t()
  def index() do
    "Limited controller index"
  end

  @doc "Function show"
  @spec show() :: String.t()
  def show() do
    "Limited controller show"
  end

end


defmodule Main do
  use Bitwise
  @moduledoc """
  Main module generated from Haxe
  
  
 * Main entry point for test
 
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("RouterBuildMacro validation test with invalid action reference", %{fileName => "Main.hx", lineNumber => 54, className => "Main", methodName => "main"})
  end

end
