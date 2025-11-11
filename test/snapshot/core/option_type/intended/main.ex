defmodule Main do
  def main() do
    _ = test_option_construction()
    _ = test_pattern_matching()
    _ = test_functional_operations()
    _ = test_beam_integration()
    _ = test_null_safety()
    _ = test_collection_operations()
  end
  defp test_option_construction() do
    some_value = {:some, "hello"}
    none_value = {:none}
    name = "world"
    nullable_name = nil
    option_from_value = MyApp.OptionTools.from_nullable(name)
    option_from_null = MyApp.OptionTools.from_nullable(nullable_name)
    some_person = {:some, "Alice"}
    no_person = {:none}
  end
  defp test_pattern_matching() do
    user = {:some, "Bob"}
    result = ((case user do
  {:some, name} -> "Hello, #{(fn -> name end).()}"
  {:none} -> "Hello, anonymous"
end))
    scores = {:some, [1, 2, 3]}
    total = ((case scores do
  {:some, score_list} ->
    length(scoreList)
  {:none} -> 0
end))
    _ = process_user({:some, "Charlie"})
    _ = process_user({:none})
  end
  defp process_user(user) do
    (case user do
      {:some, v} -> nil
      {:none} -> nil
    end)
  end
  defp test_functional_operations() do
    user = {:some, "David"}
    upper_name = MyApp.OptionTools.map(user, fn name -> String.upcase(name) end)
    long_name = MyApp.OptionTools.filter(user, fn name -> not Kernel.is_nil(:binary.match(String.downcase(name.title), query)) or name.description != nil and not Kernel.is_nil(:binary.match(String.downcase(name.description), query)) end)
    processed_user = MyApp.OptionTools.then(user, (fn -> fn name ->
      if (length(name) > 0), do: {:some, name <> "!"}, else: {:none}
    end end).())
    final_result = MyApp.OptionTools.then(OptionTools.filter(OptionTools.map(user, fn name -> String.upcase(name) end), fn name -> length(name) > 2 end), fn name -> {:some, name <> " [PROCESSED]"} end)
    greeting = MyApp.OptionTools.unwrap(user, "Anonymous")
    expensive_default = MyApp.OptionTools.lazy_unwrap(user, fn -> "Computed default" end)
    first = {:some, "First"}
    second = {:none}
    combined = MyApp.OptionTools.or_(first, second)
    lazy_second = MyApp.OptionTools.lazy_or(first, fn -> {:some, "Lazy second"} end)
  end
  defp test_beam_integration() do
    user = {:some, "Eve"}
    user_result = MyApp.OptionTools.to_result(user, "User not found")
    ok_result = {:ok, "Frank"}
    error_result = {:error, "Not found"}
    option_from_ok = MyApp.OptionTools.from_result(ok_result)
    option_from_error = MyApp.OptionTools.from_result(error_result)
    reply = MyApp.OptionTools.to_reply(user)
    valid_user = {:some, "Grace"}
    confirmed_user = MyApp.OptionTools.expect(valid_user, "Expected valid user")
  end
  defp test_null_safety() do
    maybe_null = nil
    safe_option = MyApp.OptionTools.from_nullable(maybe_null)
    result = MyApp.OptionTools.unwrap(OptionTools.map(safe_option, fn s -> length(s) end), 0)
    has_value = MyApp.OptionTools.is_some(safe_option)
    is_empty = MyApp.OptionTools.is_none(safe_option)
    back_to_nullable = MyApp.OptionTools.to_nullable(safe_option)
  end
  defp test_collection_operations() do
    options = [{:some, 1}, {:none}, {:some, 3}, {:some, 4}, {:none}]
    values = MyApp.OptionTools.values(options)
    all_options = [{:some, 1}, {:some, 2}, {:some, 3}]
    combined = MyApp.OptionTools.all(all_options)
    mixed_options = [{:some, 1}, {:none}, {:some, 3}]
    failed_combine = MyApp.OptionTools.all(mixed_options)
    processed_values = Enum.filter(Enum.map(options, fn opt -> MyApp.OptionTools.map(opt, fn x -> x * 2 end) end), fn opt -> MyApp.OptionTools.is_some(opt) end)
  end
end
