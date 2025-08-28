defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    test = TestEnum.option1("test")

    case test do
      0 -> _value = elem(test, 1)
      1 -> _data = elem(test, 1)
    Log.trace("Option2", %{"fileName" => "Main.hx", "lineNumber" => 23, "className" => "Main", "methodName" => "main"})
      2 -> Log.trace("Option3", %{"fileName" => "Main.hx", "lineNumber" => 25, "className" => "Main", "methodName" => "main"})
    end

    Log.trace("This should remain", %{"fileName" => "Main.hx", "lineNumber" => 30, "className" => "Main", "methodName" => "main"})

    _unused = "This variable is never used"

    used = "This is used"

    Log.trace(used, %{"fileName" => "Main.hx", "lineNumber" => 38, "className" => "Main", "methodName" => "main"})

    result = (42 + 1)

    Log.trace(result, %{"fileName" => "Main.hx", "lineNumber" => 44, "className" => "Main", "methodName" => "main"})

    Main.dead_code_example()
  end

  @doc "Generated from Haxe deadCodeExample"
  def dead_code_example() do
    42

    dead_var = "never executed"

    Log.trace(dead_var, %{"fileName" => "Main.hx", "lineNumber" => 54, "className" => "Main", "methodName" => "deadCodeExample"})

    0
  end

end
