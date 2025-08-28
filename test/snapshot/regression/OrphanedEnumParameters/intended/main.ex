defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Regression test for orphaned enum parameter extraction
     *
     * This test ensures that the compiler correctly handles enum parameter
     * extraction in switch statements, particularly when cases have empty
     * bodies or fall-through behavior that results in orphaned TLocal references.
     *
     * See: docs/03-compiler-development/ENUM_PARAMETER_EXTRACTION.md
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_basic_enum()

    Main.test_multiple_parameters()

    Main.test_empty_cases()

    Main.test_fall_through()

    Main.test_nested_enums()

    Main.test_mixed_cases()
  end

  @doc "Generated from Haxe testBasicEnum"
  def test_basic_enum() do
    msg = Message.created("item")

    case (case msg do :created -> 0; :updated -> 1; :deleted -> 2; :empty -> 3; _ -> -1 end) do
      {0, content} -> g_array = elem(msg, 1)
    Log.trace("Created: " <> content, %{"fileName" => "Main.hx", "lineNumber" => 38, "className" => "Main", "methodName" => "testBasicEnum"})
      {1, id, content} -> g_array = elem(msg, 1)
    g_array = elem(msg, 2)
    Log.trace("Updated " <> to_string(id) <> ": " <> content, %{"fileName" => "Main.hx", "lineNumber" => 40, "className" => "Main", "methodName" => "testBasicEnum"})
      {2, id} -> g_array = elem(msg, 1)
    Log.trace("Deleted: " <> to_string(id), %{"fileName" => "Main.hx", "lineNumber" => 42, "className" => "Main", "methodName" => "testBasicEnum"})
      3 -> Log.trace("Empty message", %{"fileName" => "Main.hx", "lineNumber" => 44, "className" => "Main", "methodName" => "testBasicEnum"})
    end
  end

  @doc "Generated from Haxe testMultipleParameters"
  def test_multiple_parameters() do
    action = Action.move(10, 20, 30)

    case (case action do :move -> 0; :rotate -> 1; :scale -> 2; _ -> -1 end) do
      {0, x, y, z} -> g_array = elem(action, 1)
    g_array = elem(action, 2)
    g_array = elem(action, 3)
    Log.trace("Moving to (" <> to_string(x) <> ", " <> to_string(y) <> ", " <> to_string(z) <> ")", %{"fileName" => "Main.hx", "lineNumber" => 53, "className" => "Main", "methodName" => "testMultipleParameters"})
      {1, angle, axis} -> g_array = elem(action, 1)
    g_array = elem(action, 2)
    Log.trace("Rotating " <> to_string(angle) <> " degrees on " <> axis, %{"fileName" => "Main.hx", "lineNumber" => 55, "className" => "Main", "methodName" => "testMultipleParameters"})
      {2, factor} -> g_array = elem(action, 1)
    Log.trace("Scaling by " <> to_string(factor), %{"fileName" => "Main.hx", "lineNumber" => 57, "className" => "Main", "methodName" => "testMultipleParameters"})
    end
  end

  @doc "Generated from Haxe testEmptyCases"
  def test_empty_cases() do
    event = Event.click(100, 200)

    case (case event do :click -> 0; :hover -> 1; :key_press -> 2; _ -> -1 end) do
      {0, __x, __y} -> g_array = elem(event, 1)
    g_array = elem(event, 2)
    nil
      {1, __x, __y} -> g_array = elem(event, 1)
    g_array = elem(event, 2)
    nil
      {2, __key} -> g_array = elem(event, 1)
    end

    Log.trace("Empty cases handled", %{"fileName" => "Main.hx", "lineNumber" => 75, "className" => "Main", "methodName" => "testEmptyCases"})
  end

  @doc "Generated from Haxe testFallThrough"
  def test_fall_through() do
    state = State.loading(50)

    description = ""

    case (case state do :loading -> 0; :processing -> 1; :complete -> 2; :error -> 3; _ -> -1 end) do
      {0, __progress} -> g_array = elem(state, 1)
    nil
      {1, progress} -> g_array = elem(state, 1)
    description = "Progress: " <> to_string(progress) <> "%"
      {2, result} -> g_array = elem(state, 1)
    description = "Done: " <> result
      {3, msg} -> g_array = elem(state, 1)
    description = "Error: " <> msg
    end

    Log.trace(description, %{"fileName" => "Main.hx", "lineNumber" => 93, "className" => "Main", "methodName" => "testFallThrough"})
  end

  @doc "Generated from Haxe testNestedEnums"
  def test_nested_enums() do
    container = Container.box(Content.text("Hello"))

    case (case container do :box -> 0; :list -> 1; :empty -> 2; _ -> -1 end) do
      {0, _content} -> g_array = elem(container, 1)
    case (case content do :text -> 0; :number -> 1; :empty -> 2; _ -> -1 end) do
      {0, str} -> g_array = elem(content, 1)
    Log.trace("Box contains text: " <> str, %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "testNestedEnums"})
      {1, n} -> g_array = elem(content, 1)
    Log.trace("Box contains number: " <> to_string(n), %{"fileName" => "Main.hx", "lineNumber" => 105, "className" => "Main", "methodName" => "testNestedEnums"})
      2 -> Log.trace("Box is empty", %{"fileName" => "Main.hx", "lineNumber" => 107, "className" => "Main", "methodName" => "testNestedEnums"})
    end
      {1, items} -> g_array = elem(container, 1)
    Log.trace("List with " <> to_string(items.length) <> " items", %{"fileName" => "Main.hx", "lineNumber" => 110, "className" => "Main", "methodName" => "testNestedEnums"})
      2 -> Log.trace("Container is empty", %{"fileName" => "Main.hx", "lineNumber" => 112, "className" => "Main", "methodName" => "testNestedEnums"})
    end
  end

  @doc "Generated from Haxe testMixedCases"
  def test_mixed_cases() do
    result = Result.success("Done", 42)

    case (case result do :success -> 0; :warning -> 1; :error -> 2; :pending -> 3; _ -> -1 end) do
      {0, msg, code} -> g_array = elem(result, 1)
    g_array = elem(result, 2)
    Log.trace("Success: " <> msg <> " (code: " <> to_string(code) <> ")", %{"fileName" => "Main.hx", "lineNumber" => 121, "className" => "Main", "methodName" => "testMixedCases"})
      {1, __msg} -> g_array = elem(result, 1)
    nil
      {2, msg, code} -> g_array = elem(result, 1)
    g_array = elem(result, 2)
    Log.trace("Error: " <> msg <> " (code: " <> to_string(code) <> ")", %{"fileName" => "Main.hx", "lineNumber" => 125, "className" => "Main", "methodName" => "testMixedCases"})
      3 -> Log.trace("Still pending...", %{"fileName" => "Main.hx", "lineNumber" => 127, "className" => "Main", "methodName" => "testMixedCases"})
    end
  end

end
