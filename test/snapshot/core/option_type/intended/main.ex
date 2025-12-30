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
    name = "world"
    nullable_name = nil
    _option_from_value = OptionTools.from_nullable(name)
    _option_from_null = OptionTools.from_nullable(nullable_name)
  end
  defp test_pattern_matching() do
    user = {:some, "Bob"}
    _result = ((case user do
  {:some, name} -> "Hello, #{name}"
  {:none} -> "Hello, anonymous"
end))
    scores = {:some, [1, 2, 3]}
    _total = ((case scores do
  {:some, score_list} -> length(score_list)
  {:none} -> 0
end))
    _ = process_user({:some, "Charlie"})
    _ = process_user({:none})
  end
  defp process_user(user) do
    (case user do
      {:some, _name} -> nil
      {:none} -> nil
    end)
  end
  defp test_functional_operations() do
    user = {:some, "David"}
    _upper_name = OptionTools.map(user, fn name -> String.upcase(name) end)
    _long_name = OptionTools.filter(user, fn name -> String.length(name) > 3 end)
    _processed_user = OptionTools.then(user, fn name ->
      if (String.length(name) > 0), do: {:some, name <> "!"}, else: {:none}
    end)
    _final_result = OptionTools.then(OptionTools.filter(OptionTools.map(user, fn name -> String.upcase(name) end), fn name -> String.length(name) > 2 end), fn name -> {:some, name <> " [PROCESSED]"} end)
    _greeting = OptionTools.unwrap(user, "Anonymous")
    _expensive_default = OptionTools.lazy_unwrap(user, fn -> "Computed default" end)
    first = {:some, "First"}
    second = {:none}
    _combined = OptionTools.or_(first, second)
    _lazy_second = OptionTools.lazy_or(first, fn -> {:some, "Lazy second"} end)
  end
  defp test_beam_integration() do
    user = {:some, "Eve"}
    _user_result = OptionTools.to_result(user, "User not found")
    ok_result = {:ok, "Frank"}
    error_result = {:error, "Not found"}
    _option_from_ok = OptionTools.from_result(ok_result)
    _option_from_error = OptionTools.from_result(error_result)
    _reply = OptionTools.to_reply(user, nil)
    valid_user = {:some, "Grace"}
    _confirmed_user = OptionTools.expect(valid_user, "Expected valid user")
  end
  defp test_null_safety() do
    maybe_null = nil
    safe_option = OptionTools.from_nullable(maybe_null)
    _result = OptionTools.unwrap(OptionTools.map(safe_option, fn s -> String.length(s) end), 0)
    _has_value = OptionTools.is_some(safe_option)
    _is_empty = OptionTools.is_none(safe_option)
    _back_to_nullable = OptionTools.to_nullable(safe_option)
  end
  defp test_collection_operations() do
    options = [{:some, 1}, {:none}, {:some, 3}, {:some, 4}, {:none}]
    _values = OptionTools.values(options)
    all_options = [{:some, 1}, {:some, 2}, {:some, 3}]
    _combined = OptionTools.all(all_options)
    mixed_options = [{:some, 1}, {:none}, {:some, 3}]
    _failed_combine = OptionTools.all(mixed_options)
    _processed_values = Enum.filter(Enum.map(options, fn opt -> OptionTools.map(opt, fn x -> x * 2 end) end), fn opt -> OptionTools.is_some(opt) end)
  end
end
