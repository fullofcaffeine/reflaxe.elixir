defmodule ExistingController do
  @moduledoc """
  ExistingController module generated from Haxe
  
  
 * Valid controller class for testing RouterBuildMacro validation
 
  """

  # Static functions
  @doc "Function index"
  @spec index() :: String.t()
  def index() do
    "Existing controller index"
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
    Log.trace("RouterBuildMacro validation test with invalid controller reference", %{"fileName" => "Main.hx", "lineNumber" => 48, "className" => "Main", "methodName" => "main"})
  end

end
