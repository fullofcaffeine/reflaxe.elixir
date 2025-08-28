defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_basic_ternary()

    Main.test_nested_ternary()

    Main.test_ternary_in_function()
  end

  @doc "Generated from Haxe testBasicTernary"
  def test_basic_ternary() do
    temp_string = nil

    config = %{name: "test"}

    temp_string = nil

    if ((config != nil)), do: temp_string = config.id, else: temp_string = "default"

    Log.trace("ID: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 14, "className" => "Main", "methodName" => "testBasicTernary"})
  end

  @doc "Generated from Haxe testNestedTernary"
  def test_nested_ternary() do
    temp_string = nil

    a = 5

    b = 10

    if ((a > 0)) do
      if ((b > 0)), do: temp_string = "both positive", else: temp_string = "a positive"
    else
      temp_string = "a not positive"
    end

    Log.trace("Result: " <> temp_string, %{"fileName" => "Main.hx", "lineNumber" => 22, "className" => "Main", "methodName" => "testNestedTernary"})
  end

  @doc "Generated from Haxe testTernaryInFunction"
  def test_ternary_in_function() do
    module = "MyModule"

    args = [1, 2, 3]

    id = nil

    spec = Main.create_spec(module, args, id)

    Log.trace("Spec: " <> Std.string(spec), %{"fileName" => "Main.hx", "lineNumber" => 32, "className" => "Main", "methodName" => "testTernaryInFunction"})
  end

  @doc "Generated from Haxe createSpec"
  def create_spec(module, args, id) do
    temp_string = nil

    if ((id != nil)), do: temp_string = id, else: temp_string = module

    %{"id" => temp_string, "module" => module, "args" => args}
  end

end
