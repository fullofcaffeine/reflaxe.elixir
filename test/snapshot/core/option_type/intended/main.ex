defmodule Main do
  def main() do
    test_option_construction()
    test_pattern_matching()
    test_functional_operations()
    test_beam_integration()
    test_null_safety()
    test_collection_operations()
  end
  defp test_option_construction() do
    _some_value = {:Some, "hello"}
    _none_value = :none
    name = "world"
    nullable_name = nil
    _option_from_value = {:FromNullable, name}
    _option_from_null = {:FromNullable, nullable_name}
    _some_person = {:Some, "Alice"}
    _no_person = :none
  end
  defp test_pattern_matching() do
    user = {:Some, "Bob"}
    _result = case (elem(user, 0)) do
  0 ->
    g = elem(user, 1)
    name = g
    "Hello, " <> name
  1 ->
    "Hello, anonymous"
end
    scores = {:Some, [1, 2, 3]}
    _total = case (elem(scores, 0)) do
  0 ->
    g = elem(scores, 1)
    score_list = g
    score_list.length
  1 ->
    0
end
    process_user({:Some, "Charlie"})
    process_user(:none)
  end
  defp process_user(user) do
    case (elem(user, 0)) do
      0 ->
        g = elem(user, 1)
        name = g
        Log.trace("Processing user: " <> name, %{:fileName => "Main.hx", :lineNumber => 68, :className => "Main", :methodName => "processUser"})
      1 ->
        Log.trace("No user to process", %{:fileName => "Main.hx", :lineNumber => 69, :className => "Main", :methodName => "processUser"})
    end
  end
  defp test_functional_operations() do
    user = {:Some, "David"}
    _upper_name = {:Map, user, fn name -> name.toUpperCase() end}
    long_name = {:Filter, user, fn name -> name.length > 3 end}
    processed_user = {:Then, user, fn name -> if (name.length > 0), do: {:Some, name <> "!"}, else: :none end}
    final_result = {:Then, {:Filter, {:Map, user, fn name -> name.toUpperCase() end}, fn name -> name.length > 2 end}, fn name -> {:Some, name <> " [PROCESSED]"} end}
    greeting = OptionTools.unwrap(user, "Anonymous")
    expensive_default = OptionTools.lazy_unwrap(user, fn -> "Computed default" end)
    first = {:Some, "First"}
    second = :none
    combined = {:Or, first, second}
    lazy_second = {:LazyOr, first, fn -> {:Some, "Lazy second"} end}
  end
  defp test_beam_integration() do
    user = {:Some, "Eve"}
    _user_result = {:ToResult, user, "User not found"}
    ok_result = {:Ok, "Frank"}
    error_result = {:Error, "Not found"}
    _option_from_ok = {:FromResult, ok_result}
    _option_from_error = {:FromResult, error_result}
    _reply = OptionTools.to_reply(user)
    valid_user = {:Some, "Grace"}
    _confirmed_user = OptionTools.expect(valid_user, "Expected valid user")
  end
  defp test_null_safety() do
    maybe_null = nil
    safe_option = {:FromNullable, maybe_null}
    _result = OptionTools.unwrap({:Map, safe_option, fn s -> s.length end}, 0)
    has_value = OptionTools.is_some(safe_option)
    is_empty = OptionTools.is_none(safe_option)
    back_to_nullable = OptionTools.to_nullable(safe_option)
  end
  defp test_collection_operations() do
    options = [{:Some, 1}, :none, {:Some, 3}, {:Some, 4}, :none]
    _values = OptionTools.values(options)
    all_options = [{:Some, 1}, {:Some, 2}, {:Some, 3}]
    _combined = {:All, all_options}
    mixed_options = [{:Some, 1}, :none, {:Some, 3}]
    _failed_combine = {:All, mixed_options}
    _processed_values = Enum.filter(Enum.map(options, fn opt -> {:Map, opt, fn x -> x * 2 end} end), fn opt -> OptionTools.is_some(opt) end)
  end
end