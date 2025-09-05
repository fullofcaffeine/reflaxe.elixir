defmodule Main do
  def main() do
    test_simple_if_push()
    test_if_else_push()
    test_conditional_accumulation()
    test_nested_if_push()
  end
  defp test_simple_if_push() do
    errors = []
    has_error = true
    if has_error do
      errors = errors ++ ["Error occurred"]
    end
    Log.trace("Simple if push result: " <> Std.string(errors), %{:fileName => "Main.hx", :lineNumber => 30, :className => "Main", :methodName => "testSimpleIfPush"})
  end
  defp test_if_else_push() do
    messages = []
    success = false
    if success do
      messages = messages ++ ["Success!"]
    else
      messages = messages ++ ["Failed!"]
    end
    Log.trace("If-else push result: " <> Std.string(messages), %{:fileName => "Main.hx", :lineNumber => 43, :className => "Main", :methodName => "testIfElsePush"})
  end
  defp test_conditional_accumulation() do
    errors = []
    errors = errors ++ ["Error 1"]
    errors = errors ++ ["Error 3"]
    Log.trace("Conditional accumulation: " <> Std.string(errors), %{:fileName => "Main.hx", :lineNumber => 54, :className => "Main", :methodName => "testConditionalAccumulation"})
  end
  defp test_nested_if_push() do
    results = []
    level1 = true
    level2 = true
    if level1 do
      results = results ++ ["Level 1"]
      if level2 do
        results = results ++ ["Level 2"]
      end
    end
    Log.trace("Nested if push: " <> Std.string(results), %{:fileName => "Main.hx", :lineNumber => 69, :className => "Main", :methodName => "testNestedIfPush"})
  end
end