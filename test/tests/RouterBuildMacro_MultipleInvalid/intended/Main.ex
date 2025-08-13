defmodule ValidController do
  use Bitwise
  @moduledoc """
  ValidController module generated from Haxe
  
  
 * Valid controller class for comparison
 
  """

  # Static functions
  @doc "Function index"
  @spec index() :: String.t()
  def index() do
    "Valid controller index"
  end

end


defmodule PartialController do
  use Bitwise
  @moduledoc """
  PartialController module generated from Haxe
  
  
 * Another valid controller with limited methods
 
  """

  # Static functions
  @doc "Function show"
  @spec show() :: String.t()
  def show() do
    "Partial controller show"
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
    Log.trace("RouterBuildMacro validation test with multiple invalid references", %{fileName: "Main.hx", lineNumber: 76, className: "Main", methodName: "main"})
  end

end
