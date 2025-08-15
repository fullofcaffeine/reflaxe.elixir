defmodule UserController do
  @moduledoc """
  UserController module generated from Haxe
  
  
 * Valid controller class for testing RouterBuildMacro validation
 
  """

  # Static functions
  @doc "Function index"
  @spec index() :: String.t()
  def index() do
    "User index"
  end

  @doc "Function show"
  @spec show() :: String.t()
  def show() do
    "User show"
  end

  @doc "Function create"
  @spec create() :: String.t()
  def create() do
    "User create"
  end

end


defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Main entry point for test
 
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("RouterBuildMacro validation test with valid controller/action references", %{"fileName" => "Main.hx", "lineNumber" => 65, "className" => "Main", "methodName" => "main"})
  end

end
