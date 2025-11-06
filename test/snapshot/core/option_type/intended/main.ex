defmodule Main do
  def main() do
    _ = test_option_construction()
    _ = test_pattern_matching()
    _ = test_functional_operations()
    _ = test_beam_integration()
    _ = test_null_safety()
    _ = test_collection_operations()
    _
  end
  defp test_option_construction() do
    _ = "hello"
    _ = {:none}
    _ = "world"
    _ = nil
    _ = MyApp.OptionTools.from_nullable(name)
    _ = MyApp.OptionTools.from_nullable(nullable_name)
    _ = Alice
    _ = {:none}
  end
  defp test_pattern_matching() do
    _ = Bob
    _ = ((case user do
  {:some, name} -> "Hello, #{(fn -> name end).()}"
  {:none} -> "Hello, anonymous"
end))
    _ = [1, 2, 3]
    _ = ((case scores do
  {:some, score_list} ->
    length(scoreList)
  {:none} -> 0
end))
    _ = process_user({:some, "Charlie"})
    _ = process_user({:none})
    _
  end
  defp process_user(user) do
    (case user do
      {:some, name} ->
        Log.trace("Processing user: #{(fn -> name end).()}", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "processUser"})
      {:none} ->
        Log.trace("No user to process", %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "processUser"})
    end)
  end
  defp test_functional_operations() do
    _ = David
    _ = MyApp.OptionTools.map(user, fn name -> String.upcase(name) end)
    _ = MyApp.OptionTools.filter(user, fn name -> not Kernel.is_nil(:binary.match(String.downcase(name.title), query)) or name.description != nil and not Kernel.is_nil(:binary.match(String.downcase(name.description), query)) end)
    _ = MyApp.OptionTools.then(user, (fn -> fn name ->
      if (length(name) > 0), do: name <> "!", else: {:none}
    end end).())
    _ = MyApp.OptionTools.then(OptionTools.filter(OptionTools.map(user, fn name -> String.upcase(name) end), fn name -> length(name) > 2 end), fn name -> {:some, name <> " [PROCESSED]"} end)
    _ = MyApp.OptionTools.unwrap(user, "Anonymous")
    _ = MyApp.OptionTools.lazy_unwrap(user, fn -> "Computed default" end)
    _ = First
    _ = {:none}
    _ = MyApp.OptionTools.or_(first, second)
    _ = MyApp.OptionTools.lazy_or(first, fn -> {:some, "Lazy second"} end)
  end
  defp test_beam_integration() do
    _ = Eve
    _ = MyApp.OptionTools.to_result(user, "User not found")
    _ = Frank
    _ = "Not found"
    _ = MyApp.OptionTools.from_result(ok_result)
    _ = MyApp.OptionTools.from_result(error_result)
    _ = MyApp.OptionTools.to_reply(user)
    _ = Grace
    _ = MyApp.OptionTools.expect(valid_user, "Expected valid user")
  end
  defp test_null_safety() do
    _ = nil
    _ = MyApp.OptionTools.from_nullable(maybe_null)
    _ = MyApp.OptionTools.unwrap(OptionTools.map(safe_option, fn s -> length(s) end), 0)
    _ = MyApp.OptionTools.is_some(safe_option)
    _ = MyApp.OptionTools.is_none(safe_option)
    _ = MyApp.OptionTools.to_nullable(safe_option)
  end
  defp test_collection_operations() do
    options = [1, {:none}, 3, 4, {:none}]
    _ = MyApp.OptionTools.values(options)
    _ = [1, 2, 3]
    _ = MyApp.OptionTools.all(all_options)
    _ = [1, {:none}, 3]
    _ = MyApp.OptionTools.all(mixed_options)
    _ = Enum.filter(Enum.map(options, fn opt -> MyApp.OptionTools.map(opt, fn x -> x * 2 end) end), fn opt -> MyApp.OptionTools.is_some(opt) end)
  end
end
