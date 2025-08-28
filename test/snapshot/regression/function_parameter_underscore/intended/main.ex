defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Regression test for function parameter underscore prefix bug
     *
     * ISSUE: Function parameters like 'appName' were being compiled to '_app_name' incorrectly,
     * causing undefined variable errors in the generated Elixir code.
     *
     * EXPECTED: Parameters should maintain their names without unwanted underscore prefixes
     * unless they are truly unused (which function parameters never are by definition).
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_function("TodoApp", 42, true)

    Main.test_optional("MyApp")

    Main.test_optional("MyApp", 8080)

    result = Main.build_name("Phoenix", "App")

    Log.trace(result, %{"fileName" => "Main.hx", "lineNumber" => 21, "className" => "Main", "methodName" => "main"})

    processed = Main.process_config(%{name: "test"})

    Log.trace(processed, %{"fileName" => "Main.hx", "lineNumber" => 25, "className" => "Main", "methodName" => "main"})
  end

  @doc "Generated from Haxe testFunction"
  def test_function(app_name, port, enabled) do
    temp_string = nil

    config = app_name <> ".Config"

    url = "http://localhost:" <> to_string(port)

    temp_string = nil

    if enabled, do: temp_string = "active", else: temp_string = "inactive"

    config <> " at " <> url <> " is " <> temp_string
  end

  @doc "Generated from Haxe testOptional"
  def test_optional(app_name, port \\ nil) do
    temp_maybe_number = nil

    temp_maybe_number = nil

    if ((port != nil)), do: temp_maybe_number = port, else: temp_maybe_number = 4000

    actual_port = temp_maybe_number

    app_name <> " on port " <> to_string(actual_port)
  end

  @doc "Generated from Haxe buildName"
  def build_name(prefix, suffix) do
    prefix <> "." <> suffix
  end

  @doc "Generated from Haxe processConfig"
  def process_config(config) do
    Std.string(config.name)
  end

end
