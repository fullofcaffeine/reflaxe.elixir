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
    Log.trace("Simple if push result: " <> Std.string(errors), %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "testSimpleIfPush"})
  end
  defp test_if_else_push() do
    messages = []
    success = false
    if success do
      messages = messages ++ ["Success!"]
    else
      messages = messages ++ ["Failed!"]
    end
    Log.trace("If-else push result: " <> Std.string(messages), %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "testIfElsePush"})
  end
  defp test_conditional_accumulation() do
    errors = []
    errors = errors ++ ["Error 1"]
    errors = errors ++ ["Error 3"]
    Log.trace("Conditional accumulation: " <> Std.string(errors), %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "testConditionalAccumulation"})
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
    Log.trace("Nested if push: " <> Std.string(results), %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "testNestedIfPush"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()