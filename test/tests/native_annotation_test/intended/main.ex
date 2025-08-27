defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    result1 = TestModule.original_name()

    result2 = TestModule.normal_method()

    Log.trace("Mapped method result: " <> result1, %{"fileName" => "Main.hx", "lineNumber" => 18, "className" => "Main", "methodName" => "main"})

    Log.trace("Normal method result: " <> result2, %{"fileName" => "Main.hx", "lineNumber" => 19, "className" => "Main", "methodName" => "main"})
  end

end
