defmodule Main do
  def main() do
    Main.test_simple_if_push()
    Main.test_if_else_push()
    Main.test_conditional_accumulation()
    Main.test_nested_if_push()
  end
  defp test_simple_if_push() do
    errors = []
    has_error = true
    if has_error, do: errors.push("Error occurred")
    Log.trace("Simple if push result: " + Std.string(errors), %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testSimpleIfPush"})
  end
  defp test_if_else_push() do
    messages = []
    success = false
    if success, do: messages.push("Success!"), else: messages.push("Failed!")
    Log.trace("If-else push result: " + Std.string(messages), %{:fileName => "Main.hx", :lineNumber => 43, :className => "Main", :methodName => "testIfElsePush"})
  end
  defp test_conditional_accumulation() do
    errors = []
    errors.push("Error 1")
    errors.push("Error 3")
    Log.trace("Conditional accumulation: " + Std.string(errors), %{:fileName => "Main.hx", :lineNumber => 54, :className => "Main", :methodName => "testConditionalAccumulation"})
  end
  defp test_nested_if_push() do
    results = []
    level_1 = true
    level_2 = true
    if level do
      results.push("Level 1")
      if level, do: results.push("Level 2")
    end
    Log.trace("Nested if push: " + Std.string(results), %{:fileName => "Main.hx", :lineNumber => 69, :className => "Main", :methodName => "testNestedIfPush"})
  end
end