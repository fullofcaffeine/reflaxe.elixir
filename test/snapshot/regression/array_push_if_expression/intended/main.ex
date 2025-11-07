defmodule Main do
  def main() do
    _ = test_simple_if_push()
    _ = test_if_else_push()
    _ = test_conditional_accumulation()
    _ = test_nested_if_push()
  end
  defp test_simple_if_push() do
    errors = []
    has_error = true
    if (has_error) do
      errors = errors ++ ["Error occurred"]
    end
    _ = Log.trace("Simple if push result: #{(fn -> inspect(errors) end).()}", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testSimpleIfPush"})
  end
  defp test_if_else_push() do
    messages = []
    success = false
    if (success) do
      messages = messages ++ ["Success!"]
    else
      messages = messages ++ ["Failed!"]
    end
    _ = Log.trace("If-else push result: #{(fn -> inspect(messages) end).()}", %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "testIfElsePush"})
  end
  defp test_conditional_accumulation() do
    errors = []
    _ = errors ++ ["Error 1"]
    _ = errors ++ ["Error 3"]
    _ = Log.trace("Conditional accumulation: #{(fn -> inspect(errors) end).()}", %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "testConditionalAccumulation"})
  end
  defp test_nested_if_push() do
    results = []
    level1 = true
    level2 = true
    if (level1) do
      _ = results ++ ["Level 1"]
      if (level2) do
        results = results ++ ["Level 2"]
      end
    end
    _ = Log.trace("Nested if push: #{(fn -> inspect(results) end).()}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "testNestedIfPush"})
  end
end
