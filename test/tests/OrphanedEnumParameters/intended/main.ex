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
  @doc "Function main"
  @spec main() :: nil
  def main() do
    (
          Main.test_basic_enum()
          Main.test_multiple_parameters()
          Main.test_empty_cases()
          Main.test_fall_through()
          Main.test_nested_enums()
          Main.test_mixed_cases()
        )
  end

  @doc "Function test_basic_enum"
  @spec test_basic_enum() :: nil
  def test_basic_enum() do
    (
          msg = Message.created("item")
          case msg do
      0 -> (
    g_array = elem(msg, 1)
    (
          content = g
          Log.trace("Created: " <> content, %{"fileName" => "Main.hx", "lineNumber" => 38, "className" => "Main", "methodName" => "testBasicEnum"})
        )
    )
      1 -> (
    g_array = elem(msg, 1)
    (
          id = g
          content = g
          Log.trace("Updated " <> to_string(id) <> ": " <> content, %{"fileName" => "Main.hx", "lineNumber" => 40, "className" => "Main", "methodName" => "testBasicEnum"})
        )
    )
      2 -> (
    g_array = elem(msg, 1)
    (
          id = g
          Log.trace("Deleted: " <> to_string(id), %{"fileName" => "Main.hx", "lineNumber" => 42, "className" => "Main", "methodName" => "testBasicEnum"})
        )
    )
      3 -> Log.trace("Empty message", %{"fileName" => "Main.hx", "lineNumber" => 44, "className" => "Main", "methodName" => "testBasicEnum"})
    end
        )
  end

  @doc "Function test_multiple_parameters"
  @spec test_multiple_parameters() :: nil
  def test_multiple_parameters() do
    (
          action = Action.move(10, 20, 30)
          case action do
      0 -> (
    g_array = elem(action, 1)
    (
          x = g
          y = g
          z = g
          Log.trace("Moving to (" <> to_string(x) <> ", " <> to_string(y) <> ", " <> to_string(z) <> ")", %{"fileName" => "Main.hx", "lineNumber" => 53, "className" => "Main", "methodName" => "testMultipleParameters"})
        )
    )
      1 -> (
    g_array = elem(action, 1)
    (
          angle = g
          axis = g
          Log.trace("Rotating " <> to_string(angle) <> " degrees on " <> axis, %{"fileName" => "Main.hx", "lineNumber" => 55, "className" => "Main", "methodName" => "testMultipleParameters"})
        )
    )
      2 -> (
    g_array = elem(action, 1)
    (
          factor = g
          Log.trace("Scaling by " <> to_string(factor), %{"fileName" => "Main.hx", "lineNumber" => 57, "className" => "Main", "methodName" => "testMultipleParameters"})
        )
    )
    end
        )
  end

  @doc "Function test_empty_cases"
  @spec test_empty_cases() :: nil
  def test_empty_cases() do
    (
          event = Event.click(100, 200)
          case event do
      0 -> (
    g_array = elem(event, 1)
    (
          g
          g
          nil
        )
    )
      1 -> (
    g_array = elem(event, 1)
    (
          g
          g
          nil
        )
    )
      2 -> (
    g_array = elem(event, 1)
    g
    )
    end
          Log.trace("Empty cases handled", %{"fileName" => "Main.hx", "lineNumber" => 75, "className" => "Main", "methodName" => "testEmptyCases"})
        )
  end

  @doc "Function test_fall_through"
  @spec test_fall_through() :: nil
  def test_fall_through() do
    (
          state = State.loading(50)
          description = ""
          case state do
      0 -> (
    g_array = elem(state, 1)
    (
          g
          nil
        )
    )
      1 -> (
    g_array = elem(state, 1)
    (
          progress = g
          description = "Progress: " <> to_string(progress) <> "%"
        )
    )
      2 -> (
    g_array = elem(state, 1)
    (
          result = g
          description = "Done: " <> result
        )
    )
      3 -> (
    g_array = elem(state, 1)
    (
          msg = g
          description = "Error: " <> msg
        )
    )
    end
          Log.trace(description, %{"fileName" => "Main.hx", "lineNumber" => 93, "className" => "Main", "methodName" => "testFallThrough"})
        )
  end

  @doc "Function test_nested_enums"
  @spec test_nested_enums() :: nil
  def test_nested_enums() do
    (
          container = Container.box(Content.text("Hello"))
          case container do
      0 -> (
    g_array = elem(container, 1)
    (
          content = g
          case content do
      0 -> (
    g_array = elem(content, 1)
    (
          str = g
          Log.trace("Box contains text: " <> str, %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "testNestedEnums"})
        )
    )
      1 -> (
    g_array = elem(content, 1)
    (
          n = g
          Log.trace("Box contains number: " <> to_string(n), %{"fileName" => "Main.hx", "lineNumber" => 105, "className" => "Main", "methodName" => "testNestedEnums"})
        )
    )
      2 -> Log.trace("Box is empty", %{"fileName" => "Main.hx", "lineNumber" => 107, "className" => "Main", "methodName" => "testNestedEnums"})
    end
        )
    )
      1 -> (
    g_array = elem(container, 1)
    (
          g_array = elem(container, 1)
          items = g
          Log.trace("List with " <> to_string(items.length) <> " items", %{"fileName" => "Main.hx", "lineNumber" => 110, "className" => "Main", "methodName" => "testNestedEnums"})
        )
    )
      2 -> Log.trace("Container is empty", %{"fileName" => "Main.hx", "lineNumber" => 112, "className" => "Main", "methodName" => "testNestedEnums"})
    end
        )
  end

  @doc "Function test_mixed_cases"
  @spec test_mixed_cases() :: nil
  def test_mixed_cases() do
    (
          result = Result.success("Done", 42)
          case result do
      {:ok, _} -> (
    g_array = elem(result, 1)
    (
          msg = g
          code = g
          Log.trace("Success: " <> msg <> " (code: " <> to_string(code) <> ")", %{"fileName" => "Main.hx", "lineNumber" => 121, "className" => "Main", "methodName" => "testMixedCases"})
        )
    )
      {:error, _} -> (
    g_array = elem(result, 1)
    (
          g
          nil
        )
    )
      {:error, _} -> (
    g_array = elem(result, 1)
    (
          msg = g
          code = g
          Log.trace("Error: " <> msg <> " (code: " <> to_string(code) <> ")", %{"fileName" => "Main.hx", "lineNumber" => 125, "className" => "Main", "methodName" => "testMixedCases"})
        )
    )
      {:error, _} -> Log.trace("Still pending...", %{"fileName" => "Main.hx", "lineNumber" => 127, "className" => "Main", "methodName" => "testMixedCases"})
    end
        )
  end

end
