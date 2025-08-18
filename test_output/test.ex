defmodule Test do
  @moduledoc "Test module generated from Haxe"

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    date = Date_Impl_._new(2024, 0, 1, 12, 0, 0)
    Log.trace("Date compilation test successful", %{"fileName" => "Test.hx", "lineNumber" => 5, "className" => "Test", "methodName" => "main"})
    Log.trace("Current time: " <> Date_Impl_.toString(Date_Impl_.now()), %{"fileName" => "Test.hx", "lineNumber" => 6, "className" => "Test", "methodName" => "main"})
    Log.trace("Date created: " <> Date_Impl_.toString(date), %{"fileName" => "Test.hx", "lineNumber" => 7, "className" => "Test", "methodName" => "main"})
  end

end
