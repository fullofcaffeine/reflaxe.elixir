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
    _some_value = "hello"
    _none_value = :none
    name = "world"
    nullable_name = nil
    _option_from_value = OptionTools.from_nullable(name)
    _option_from_null = OptionTools.from_nullable(nullable_name)
    _some_person = Alice
    _no_person = :none
  end
  defp test_pattern_matching() do
    user = Bob
    _result = case (user) do
  {:some, g} ->
    g = elem(user, 1)
    name = g
    "Hello, " <> name
  {:none} ->
    "Hello, anonymous"
end
    scores = [1, 2, 3]
    _total = case (scores) do
  {:some, g} ->
    g = elem(scores, 1)
    score_list = g
    length(score_list)
  {:none} ->
    0
end
    process_user(Charlie)
    process_user(:none)
  end
  defp process_user(_user) do
    case (_user) do
      {:some, g} ->
        g = elem(_user, 1)
        name = g
        Log.trace("Processing user: " <> name, %{:file_name => "Main.hx", :line_number => 68, :class_name => "Main", :method_name => "processUser"})
      {:none} ->
        Log.trace("No user to process", %{:file_name => "Main.hx", :line_number => 69, :class_name => "Main", :method_name => "processUser"})
    end
  end
  defp test_functional_operations() do
    user = David
    _upper_name = OptionTools.map(user, fn name -> name.to_upper_case() end)
    long_name = OptionTools.filter(user, fn name -> length(name) > 3 end)
    processed_user = OptionTools.then(user, fn name -> if (length(name) > 0), do: name <> "!", else: :none end)
    final_result = OptionTools.then(OptionTools.filter(OptionTools.map(user, fn name -> name.to_upper_case() end), fn name -> length(name) > 2 end), fn name -> {:some, name <> " [PROCESSED]"} end)
    greeting = OptionTools.unwrap(user, "Anonymous")
    expensive_default = OptionTools.lazy_unwrap(user, fn -> "Computed default" end)
    first = First
    second = :none
    combined = OptionTools.or(first, second)
    lazy_second = OptionTools.lazy_or(first, fn -> {:some, "Lazy second"} end)
  end
  defp test_beam_integration() do
    user = Eve
    _user_result = OptionTools.to_result(user, "User not found")
    ok_result = Frank
    error_result = "Not found"
    _option_from_ok = OptionTools.from_result(ok_result)
    _option_from_error = OptionTools.from_result(error_result)
    _reply = OptionTools.to_reply(user)
    valid_user = Grace
    _confirmed_user = OptionTools.expect(valid_user, "Expected valid user")
  end
  defp test_null_safety() do
    maybe_null = nil
    safe_option = OptionTools.from_nullable(maybe_null)
    _result = OptionTools.unwrap(OptionTools.map(safe_option, fn s -> length(s) end), 0)
    has_value = OptionTools.is_some(safe_option)
    is_empty = OptionTools.is_none(safe_option)
    back_to_nullable = OptionTools.to_nullable(safe_option)
  end
  defp test_collection_operations() do
    options = [1, :none, 3, 4, :none]
    _values = OptionTools.values(options)
    all_options = [1, 2, 3]
    _combined = OptionTools.all(all_options)
    mixed_options = [1, :none, 3]
    _failed_combine = OptionTools.all(mixed_options)
    _processed_values = Enum.filter(Enum.map(options, fn opt -> OptionTools.map(opt, fn x -> x * 2 end) end), fn opt -> OptionTools.is_some(opt) end)
  end
end