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
      :created -> (
          g_array = _ = elem(msg, 1)
          (
          content = g_array
          Log.trace("Created: " <> content, %{"fileName" => "Main.hx", "lineNumber" => 38, "className" => "Main", "methodName" => "testBasicEnum"})
        )
        )
      :updated -> (
          g_array = _ = elem(msg, 1)
          g_array = _ = elem(msg, 2)
          (
          id = g_array
          content = g_array
          Log.trace("Updated " <> to_string(id) <> ": " <> content, %{"fileName" => "Main.hx", "lineNumber" => 40, "className" => "Main", "methodName" => "testBasicEnum"})
        )
        )
      :deleted -> (
          g_array = _ = elem(msg, 1)
          (
          id = g_array
          Log.trace("Deleted: " <> to_string(id), %{"fileName" => "Main.hx", "lineNumber" => 42, "className" => "Main", "methodName" => "testBasicEnum"})
        )
        )
      :empty -> Log.trace("Empty message", %{"fileName" => "Main.hx", "lineNumber" => 44, "className" => "Main", "methodName" => "testBasicEnum"})
    end
        )
  end

  @doc "Function test_multiple_parameters"
  @spec test_multiple_parameters() :: nil
  def test_multiple_parameters() do
    (
          action = Action.move(10, 20, 30)
          case action do
      :move -> g_array = _ = elem(action, 1)
    g_array = _ = elem(action, 2)
    g_array = _ = elem(action, 3)
    x = g_array
    y = g_array
    z = g_array
    Log.trace("Moving to (" <> to_string(x) <> ", " <> to_string(y) <> ", " <> to_string(z) <> ")", %{"fileName" => "Main.hx", "lineNumber" => 53, "className" => "Main", "methodName" => "testMultipleParameters"})
      :rotate -> (
          g_array = _ = elem(action, 1)
          g_array = _ = elem(action, 2)
          angle = g_array
          axis = g_array
          Log.trace("Rotating " <> to_string(angle) <> " degrees on " <> axis, %{"fileName" => "Main.hx", "lineNumber" => 55, "className" => "Main", "methodName" => "testMultipleParameters"})
        )
      :scale -> (
          g_array = _ = elem(action, 1)
          factor = g_array
          Log.trace("Scaling by " <> to_string(factor), %{"fileName" => "Main.hx", "lineNumber" => 57, "className" => "Main", "methodName" => "testMultipleParameters"})
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
      :click -> (
          _ = elem(event, 1)
          _ = elem(event, 2)
          nil
        )
      :hover -> (
          _ = elem(event, 1)
          _ = elem(event, 2)
          nil
        )
      :key_press -> _ = elem(event, 1)
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
      :loading -> (
          _ = elem(state, 1)
          nil
        )
      :processing -> (
          g_array = _ = elem(state, 1)
          (
          progress = g_array
          description = "Progress: " <> to_string(progress) <> "%"
        )
        )
      :complete -> (
          g_array = _ = elem(state, 1)
          result = g_array
          description = "Done: " <> result
        )
      :error -> (
          g_array = _ = elem(state, 1)
          msg = g_array
          description = "Error: " <> msg
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
      :box -> (
          g_array = _ = elem(container, 1)
          content = g_array
          case content do
      :text -> (
          g_array = _ = elem(content, 1)
          str = g_array
          Log.trace("Box contains text: " <> str, %{"fileName" => "Main.hx", "lineNumber" => 103, "className" => "Main", "methodName" => "testNestedEnums"})
        )
      :number -> (
          g_array = _ = elem(content, 1)
          n = g_array
          Log.trace("Box contains number: " <> to_string(n), %{"fileName" => "Main.hx", "lineNumber" => 105, "className" => "Main", "methodName" => "testNestedEnums"})
        )
      :empty -> Log.trace("Box is empty", %{"fileName" => "Main.hx", "lineNumber" => 107, "className" => "Main", "methodName" => "testNestedEnums"})
    end
        )
      :list -> (
          g_array = elem(container, 1)
          items = g_array
          Log.trace("List with " <> to_string(items.length) <> " items", %{"fileName" => "Main.hx", "lineNumber" => 110, "className" => "Main", "methodName" => "testNestedEnums"})
        )
      :empty -> Log.trace("Container is empty", %{"fileName" => "Main.hx", "lineNumber" => 112, "className" => "Main", "methodName" => "testNestedEnums"})
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
          g_array = _ = elem(result, 1)
          g_array = _ = elem(result, 2)
          (
          msg = g_array
          code = g_array
          Log.trace("Success: " <> msg <> " (code: " <> to_string(code) <> ")", %{"fileName" => "Main.hx", "lineNumber" => 121, "className" => "Main", "methodName" => "testMixedCases"})
        )
        )
      {:error, _} -> (
          _ = elem(result, 1)
          nil
        )
      {:error, _} -> (
          g_array = _ = elem(result, 1)
          g_array = _ = elem(result, 2)
          (
          msg = g_array
          code = g_array
          Log.trace("Error: " <> msg <> " (code: " <> to_string(code) <> ")", %{"fileName" => "Main.hx", "lineNumber" => 125, "className" => "Main", "methodName" => "testMixedCases"})
        )
        )
      {:error, _} -> Log.trace("Still pending...", %{"fileName" => "Main.hx", "lineNumber" => 127, "className" => "Main", "methodName" => "testMixedCases"})
    end
        )
  end

end
