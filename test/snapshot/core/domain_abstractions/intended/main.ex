defmodule Main do
  def main() do
    _ = test_email_validation()
    _ = test_user_id_validation()
    _ = test_positive_int_arithmetic()
    _ = test_non_empty_string_operations()
    _ = test_functional_composition()
    _ = test_error_handling()
    _ = test_real_world_scenarios()
    nil
  end
  defp test_email_validation() do
    _email_result = (case Email_Impl_.parse("user@example.com") do
      {:ok, email} ->
        _domain = Email_Impl_.get_domain(email)
        _local_part = Email_Impl_.get_local_part(email)
        _is_example_domain = Email_Impl_.has_domain(email, "example.com")
        _normalized = Email_Impl_.normalize(email)
        nil
      {:error, _error} -> nil
    end)
    invalid_emails = ["invalid-email", "@example.com", "user@", "user@@example.com", "", "user space@example.com"]
    _g = 0
    _ = Enum.each(invalid_emails, fn invalid_email ->
  (case Email_Impl_.parse(invalid_email) do
    {:ok, _value} -> nil
    {:error, _error} -> nil
  end)
end)
    email1_result = Email_Impl_.parse("Test@Example.Com")
    email2_result = Email_Impl_.parse("test@example.com")
    if (ResultTools.is_ok(email1_result) and ResultTools.is_ok(email2_result)) do
      email1 = ResultTools.unwrap(email1_result)
      email2 = ResultTools.unwrap(email2_result)
      _are_equal = Email_Impl_.equals(email1, email2)
      nil
    end
  end
  defp test_user_id_validation() do
    valid_ids = ["user123", "Alice", "Bob42", "testUser"]
    g = 0
    _ = Enum.each(valid_ids, fn valid_id ->
  (case UserId_Impl_.parse(valid_id) do
    {:ok, user_id} ->
      _length = UserId_Impl_.length(user_id)
      _normalized = UserId_Impl_.normalize(user_id)
      _starts_with_user = UserId_Impl_.starts_with_ignore_case(user_id, "user")
      nil
    {:error, _error} -> nil
  end)
end)
    invalid_ids = ["ab", "user@123", "user 123", "user-123", "", Enum.join((fn ->
  (fn ->
  g = []
  g = Enum.reduce(0..59//1, g, fn _, g_acc -> Enum.concat(g_acc, ["a"]) end)
  g
end).()
end).(), "")]
    _g = 0
    _ = Enum.each(invalid_ids, fn invalid_id ->
  (case UserId_Impl_.parse(invalid_id) do
    {:ok, _value} -> nil
    {:error, _error} -> nil
  end)
end)
    id1_result = UserId_Impl_.parse("User123")
    id2_result = UserId_Impl_.parse("user123")
    if (ResultTools.is_ok(id1_result) and ResultTools.is_ok(id2_result)) do
      id1 = ResultTools.unwrap(id1_result)
      id2 = ResultTools.unwrap(id2_result)
      _exact_equal = UserId_Impl_.equals(id1, id2)
      _case_insensitive_equal = UserId_Impl_.equals_ignore_case(id1, id2)
      nil
    end
  end
  defp test_positive_int_arithmetic() do
    valid_numbers = [1, 5, 42, 100, 999]
    _g = 0
    _ = Enum.each(valid_numbers, fn valid_num ->
  (case PositiveInt_Impl_.parse(valid_num) do
    {:ok, pos_int} ->
      _doubled = PositiveInt_Impl_.multiply(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(2)))
      _added = PositiveInt_Impl_.add(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(10)))
      subtract_result = PositiveInt_Impl_.safe_sub(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(1)))
      (case subtract_result do
        {:ok, _result} -> nil
        {:error, _error} -> nil
      end)
      five = ResultTools.unwrap(PositiveInt_Impl_.parse(5))
      _is_greater = PositiveInt_Impl_.greater_than(pos_int, five)
      _min = PositiveInt_Impl_.min(pos_int, five)
      _max = PositiveInt_Impl_.max(pos_int, five)
      nil
    {:error, _error} -> nil
  end)
end)
    invalid_numbers = [0, -1, -42, -100]
    _g = 0
    _ = Enum.each(invalid_numbers, fn invalid_num ->
  (case PositiveInt_Impl_.parse(invalid_num) do
    {:ok, _value} -> nil
    {:error, _error} -> nil
  end)
end)
    five = ResultTools.unwrap(PositiveInt_Impl_.parse(5))
    ten = ResultTools.unwrap(PositiveInt_Impl_.parse(10))
    (case PositiveInt_Impl_.safe_sub(five, ten) do
      {:ok, _value} -> nil
      {:error, _error} -> nil
    end)
    twenty = ResultTools.unwrap(PositiveInt_Impl_.parse(20))
    four = ResultTools.unwrap(PositiveInt_Impl_.parse(4))
    three = ResultTools.unwrap(PositiveInt_Impl_.parse(3))
    (case PositiveInt_Impl_.safe_div(twenty, four) do
      {:ok, _result} -> nil
      {:error, _error} -> nil
    end)
    (case PositiveInt_Impl_.safe_div(twenty, three) do
      {:ok, _result} -> nil
      {:error, _error} -> nil
    end)
  end
  defp test_non_empty_string_operations() do
    valid_strings = ["hello", "world", "test", "NonEmptyString"]
    _g = 0
    _ = Enum.each(valid_strings, fn valid_str ->
  (case NonEmptyString_Impl_.parse(valid_str) do
    {:ok, non_empty_str} ->
      _length = NonEmptyString_Impl_.length(non_empty_str)
      _upper = NonEmptyString_Impl_.to_upper_case(non_empty_str)
      _lower = NonEmptyString_Impl_.to_lower_case(non_empty_str)
      other = ResultTools.unwrap(NonEmptyString_Impl_.parse("!"))
      _concatenated = NonEmptyString_Impl_.concat(non_empty_str, other)
      _first_char = NonEmptyString_Impl_.first_char(non_empty_str)
      _last_char = NonEmptyString_Impl_.last_char(non_empty_str)
      (case NonEmptyString_Impl_.safe_substring(non_empty_str, 1) do
        {:ok, _substr} -> nil
        {:error, _error} -> nil
      end)
    {:error, _error} -> nil
  end)
end)
    invalid_strings = ["", "   ", "\t\n"]
    _g = 0
    _ = Enum.each(invalid_strings, fn invalid_str ->
  (case NonEmptyString_Impl_.parse(invalid_str) do
    {:ok, _value} -> nil
    {:error, _error} -> nil
  end)
end)
    whitespace_strings = ["  hello  ", "\tworld\n", "  test  "]
    _g = 0
    _ = Enum.each(whitespace_strings, fn whitespace_str ->
  (case NonEmptyString_Impl_.parse_and_trim(whitespace_str) do
    {:ok, _trimmed} -> nil
    {:error, _error} -> nil
  end)
end)
    test_str = ResultTools.unwrap(NonEmptyString_Impl_.parse("Hello World"))
    _starts_with_hello = NonEmptyString_Impl_.starts_with(test_str, "Hello")
    _ends_with_world = NonEmptyString_Impl_.ends_with(test_str, "World")
    _contains_space = NonEmptyString_Impl_.contains(test_str, " ")
    (case NonEmptyString_Impl_.safe_replace(test_str, "World", "Universe") do
      {:ok, _replaced} -> nil
      {:error, _error} -> nil
    end)
    parts = NonEmptyString_Impl_.split_non_empty(test_str, " ")
    _g = 0
    _ = Enum.each(parts, fn _ -> nil end)
  end
  defp test_functional_composition() do
    _email_chain = ResultTools.unwrap_or(ResultTools.map(ResultTools.map(Email_Impl_.parse("USER@EXAMPLE.COM"), fn email -> Email_Impl_.normalize(email) end), fn email -> Email_Impl_.get_domain(email) end), "unknown")
    _user_id_chain = ResultTools.unwrap_or(ResultTools.filter(ResultTools.map(UserId_Impl_.parse("TestUser123"), fn user_id -> UserId_Impl_.normalize(user_id) end), fn user_id -> UserId_Impl_.starts_with(user_id, "test") end, "UserId does not start with 'test'"), ResultTools.unwrap(UserId_Impl_.parse("defaultuser")))
    _math_chain = ResultTools.unwrap_or(ResultTools.map(ResultTools.flat_map(PositiveInt_Impl_.parse(10), fn n -> PositiveInt_Impl_.safe_sub(n, ResultTools.unwrap(PositiveInt_Impl_.parse(3))) end), fn n -> PositiveInt_Impl_.multiply(n, ResultTools.unwrap(PositiveInt_Impl_.parse(2))) end), ResultTools.unwrap(PositiveInt_Impl_.parse(1)))
    _string_chain = ResultTools.unwrap_or(ResultTools.flat_map(ResultTools.map(ResultTools.flat_map(NonEmptyString_Impl_.parse_and_trim("  hello world  "), fn s -> NonEmptyString_Impl_.safe_trim(s) end), fn s -> NonEmptyString_Impl_.to_upper_case(s) end), fn s -> NonEmptyString_Impl_.safe_replace(s, "WORLD", "UNIVERSE") end), ResultTools.unwrap(NonEmptyString_Impl_.parse("fallback")))
    _composition_result = (case build_user_profile("user123", "  alice@example.com  ", "5") do
      {:ok, _profile} -> nil
      {:error, _error} -> nil
    end)
  end
  defp test_error_handling() do
    invalid_inputs = [%{:email => "invalid-email", :user_id => "ab", :score => "0"}, %{:email => "user@domain", :user_id => "user@123", :score => "-5"}, %{:email => "", :user_id => "", :score => "not-a-number"}]
    _g = 0
    _ = Enum.each(invalid_inputs, fn input ->
  (case build_user_profile(input.user_id, input.email, input.score) do
    {:ok, _value} -> nil
    {:error, _error} -> nil
  end)
end)
    edge_cases = [%{:email => "a@b.co", :user_id => "usr", :score => "1"}, %{:email => "very.long.email.address@very.long.domain.name.example.com", :user_id => "user123456789", :score => "999"}]
    _g = 0
    _ = Enum.each(edge_cases, fn edge_case ->
  (case build_user_profile(edge_case.user_id, edge_case.email, edge_case.score) do
    {:ok, _profile} -> nil
    {:error, _error} -> nil
  end)
end)
  end
  defp test_real_world_scenarios() do
    registration_data = [%{:user_id => "alice123", :email => "alice@example.com", :preferred_name => "Alice Smith"}, %{:user_id => "bob456", :email => "bob.jones@company.org", :preferred_name => "Bob"}, %{:user_id => "charlie", :email => "charlie@test.dev", :preferred_name => "Charlie Brown"}]
    valid_users = []
    _g = 0
    valid_users = Enum.reduce(registration_data, valid_users, fn user_data, valid_users_acc ->
      user_result = create_user(user_data.user_id, user_data.email, user_data.preferred_name)
      ((case user_result do
  {:ok, user} ->
    valid_users_acc = Enum.concat(valid_users_acc, [user])
    nil
    valid_users_acc
  {:error, error} ->
    nil
    error
end))
    end)
    config_data = [%{:timeout => "30", :retries => "3", :name => "production"}, %{:timeout => "0", :retries => "5", :name => ""}, %{:timeout => "60", :retries => "-1", :name => "test"}]
    _g = 0
    _ = Enum.each(config_data, fn config ->
  config_result = validate_configuration(config.timeout, config.retries, config.name)
  (case config_result do
    {:ok, _valid_config} -> nil
    {:error, _error} -> nil
  end)
end)
  end
  defp build_user_profile(user_id_str, email_str, score_str) do
    ResultTools.flat_map(ResultTools.map_error(UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), fn user_id ->
      ResultTools.flat_map(ResultTools.map_error(Email_Impl_.parse(StringTools.ltrim(StringTools.rtrim(email_str))), fn e -> "Invalid Email: " <> e end), fn email ->
        score_int = ((case Integer.parse(score_str) do
  {num, _} -> num
  :error -> nil
end))
        if (Kernel.is_nil(score_int)) do
          {:error, "Invalid score: " <> score_str}
        else
          ResultTools.map(ResultTools.map_error(PositiveInt_Impl_.parse(score_int), fn e -> "Invalid score: " <> e end), fn score -> %{:user_id => user_id, :email => email, :score => score} end)
        end
      end)
    end)
  end
  defp create_user(user_id_str, email_str, name_str) do
    ResultTools.flat_map(ResultTools.map_error(UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), fn user_id -> ResultTools.flat_map(ResultTools.map_error(Email_Impl_.parse(email_str), fn e -> "Invalid Email: " <> e end), fn email -> ResultTools.map(ResultTools.map_error(NonEmptyString_Impl_.parse_and_trim(name_str), fn e -> "Invalid Name: " <> e end), fn display_name -> %{:user_id => user_id, :email => email, :display_name => display_name} end) end) end)
  end
  defp validate_configuration(timeout_str, retries_str, name_str) do
    timeout_int = ((case Integer.parse(timeout_str) do
  {num, _} -> num
  :error -> nil
end))
    retries_int = ((case Integer.parse(retries_str) do
  {num, _} -> num
  :error -> nil
end))
    if (Kernel.is_nil(timeout_int)) do
      {:error, "Timeout must be a number: " <> timeout_str}
    else
      if (Kernel.is_nil(retries_int)) do
        {:error, "Retries must be a number: " <> retries_str}
      else
        ResultTools.flat_map(ResultTools.map_error(PositiveInt_Impl_.parse(timeout_int), fn e -> "Invalid timeout: " <> e end), fn timeout -> ResultTools.flat_map(ResultTools.map_error(PositiveInt_Impl_.parse(retries_int), fn e -> "Invalid retries: " <> e end), fn retries -> ResultTools.map(ResultTools.map_error(NonEmptyString_Impl_.parse_and_trim(name_str), fn e -> "Invalid name: " <> e end), fn name -> %{:timeout => timeout, :retries => retries, :name => name} end) end) end)
      end
    end
  end
end
