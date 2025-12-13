defmodule Main do
  defp test_email_validation() do
    email_result = (case MyApp.Email_Impl_.parse("user@example.com") do
      {:ok, value} ->
        email = value
        domain = MyApp.Email_Impl_.get_domain(email)
        local_part = MyApp.Email_Impl_.get_local_part(email)
        is_example_domain = MyApp.Email_Impl_.has_domain(email, "example.com")
        normalized = MyApp.Email_Impl_.normalize(email)
        nil
      {:error, __reason} -> nil
    end)
    invalid_emails = ["invalid-email", "@example.com", "user@", "user@@example.com", "", "user space@example.com"]
    _ = Enum.each(invalid_emails, (fn -> fn item ->
    (case Email_Impl_.parse(item) do
    {:ok, value} -> nil
    {:error, reason} ->
      nil
  end)
end end).())
    email1_result = MyApp.Email_Impl_.parse("Test@Example.Com")
    email2_result = MyApp.Email_Impl_.parse("test@example.com")
    if (MyApp.ResultTools.is_ok(email1_result) and MyApp.ResultTools.is_ok(email2_result)) do
      email = MyApp.ResultTools.unwrap(email1_result)
      email = MyApp.ResultTools.unwrap(email2_result)
      are_equal = MyApp.Email_Impl_.equals(email1, email2)
      nil
    end
  end
  defp test_user_id_validation() do
    valid_ids = ["user123", "Alice", "Bob42", "testUser"]
    _ = Enum.each(valid_ids, (fn -> fn item ->
    (case UserId_Impl_.parse(item) do
    {:ok, value} ->
      user_id = value
      length = UserId_Impl_.length(user_id)
      normalized = UserId_Impl_.normalize(user_id)
      starts_with_user = UserId_Impl_.starts_with_ignore_case(user_id, "user")
      nil
    {:error, reason} ->
      nil
  end)
end end).())
    invalid_ids = ["ab", "user@123", "user 123", "user-123", "", Enum.join((fn ->
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, (fn -> fn _, acc ->
    if (0 < 60) do
      i = 1
      [].push("a")
      {:cont, acc}
    else
      {:halt, acc}
    end
  end end).())
  []
end).(), "")]
    _ = Enum.each(invalid_ids, (fn -> fn item ->
    (case UserId_Impl_.parse(item) do
    {:ok, value} -> nil
    {:error, reason} ->
      nil
  end)
end end).())
    id1_result = MyApp.UserId_Impl_.parse("User123")
    id2_result = MyApp.UserId_Impl_.parse("user123")
    if (MyApp.ResultTools.is_ok(id1_result) and MyApp.ResultTools.is_ok(id2_result)) do
      _ = MyApp.ResultTools.unwrap(id1_result)
      _ = MyApp.ResultTools.unwrap(id2_result)
      exact_equal = MyApp.UserId_Impl_.equals(id1, id2)
      case_insensitive_equal = MyApp.UserId_Impl_.equals_ignore_case(id1, id2)
      nil
    end
  end
  defp test_positive_int_arithmetic() do
    valid_numbers = [1, 5, 42, 100, 999]
    _ = Enum.each(valid_numbers, (fn -> fn item ->
    (case PositiveInt_Impl_.parse(item) do
    {:ok, value} ->
      pos_int = value
      doubled = PositiveInt_Impl_.multiply(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(2)))
      added = PositiveInt_Impl_.add(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(10)))
      subtract_result = PositiveInt_Impl_.safe_sub(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(1)))
      (case item do
        {:ok, value} ->
          result = value
          nil
        {:error, reason} ->
          nil
      end)
      five = ResultTools.unwrap(PositiveInt_Impl_.parse(5))
      is_greater = PositiveInt_Impl_.greater_than(pos_int, five)
      min = PositiveInt_Impl_.min(pos_int, five)
      max = PositiveInt_Impl_.max(pos_int, five)
      nil
    {:error, reason} ->
      nil
  end)
end end).())
    invalid_numbers = [0, -1, -42, -100]
    _ = Enum.each(invalid_numbers, (fn -> fn item ->
    (case PositiveInt_Impl_.parse(item) do
    {:ok, value} -> nil
    {:error, reason} ->
      nil
  end)
end end).())
    five = MyApp.ResultTools.unwrap(PositiveInt_Impl_.parse(5))
    ten = MyApp.ResultTools.unwrap(PositiveInt_Impl_.parse(10))
    (case MyApp.PositiveInt_Impl_.safe_sub(five, ten) do
      {:ok, value} ->
        _nil = value
        nil
      {:error, __reason} -> nil
    end)
    twenty = MyApp.ResultTools.unwrap(PositiveInt_Impl_.parse(20))
    four = MyApp.ResultTools.unwrap(PositiveInt_Impl_.parse(4))
    three = MyApp.ResultTools.unwrap(PositiveInt_Impl_.parse(3))
    (case MyApp.PositiveInt_Impl_.safe_div(twenty, four) do
      {:ok, value} ->
        _nil = value
        _result = value
        nil
      {:error, __reason} -> nil
    end)
    (case MyApp.PositiveInt_Impl_.safe_div(twenty, three) do
      {:ok, value} ->
        _nil = value
        _result = value
        nil
      {:error, __reason} -> nil
    end)
  end
  defp test_non_empty_string_operations() do
    valid_strings = ["hello", "world", "test", "NonEmptyString"]
    _ = Enum.each(valid_strings, (fn -> fn item ->
    (case NonEmptyString_Impl_.parse(item) do
    {:ok, value} ->
      non_empty_str = value
      length = NonEmptyString_Impl_.length(non_empty_str)
      upper = NonEmptyString_Impl_.to_upper_case(non_empty_str)
      lower = NonEmptyString_Impl_.to_lower_case(non_empty_str)
      other = ResultTools.unwrap(NonEmptyString_Impl_.parse("!"))
      concatenated = NonEmptyString_Impl_.concat(non_empty_str, other)
      first_char = NonEmptyString_Impl_.first_char(non_empty_str)
      last_char = NonEmptyString_Impl_.last_char(non_empty_str)
      (case NonEmptyString_Impl_.safe_substring(non_empty_str, 1) do
        {:ok, value} ->
          substr = value
          nil
        {:error, reason} ->
          nil
      end)
    {:error, reason} ->
      nil
  end)
end end).())
    invalid_strings = ["", "   ", "\t\n"]
    _ = Enum.each(invalid_strings, (fn -> fn item ->
    (case NonEmptyString_Impl_.parse(item) do
    {:ok, value} -> nil
    {:error, reason} ->
      nil
  end)
end end).())
    whitespace_strings = ["  hello  ", "\tworld\n", "  test  "]
    _ = Enum.each(whitespace_strings, (fn -> fn item ->
    (case NonEmptyString_Impl_.parse_and_trim(item) do
    {:ok, value} ->
      trimmed = value
      nil
    {:error, reason} ->
      nil
  end)
end end).())
    test_str = MyApp.ResultTools.unwrap(NonEmptyString_Impl_.parse("Hello World"))
    starts_with_hello = MyApp.NonEmptyString_Impl_.starts_with(test_str, "Hello")
    ends_with_world = MyApp.NonEmptyString_Impl_.ends_with(test_str, "World")
    contains_space = MyApp.NonEmptyString_Impl_.contains(test_str, " ")
    (case MyApp.NonEmptyString_Impl_.safe_replace(test_str, "World", "Universe") do
      {:ok, value} ->
        _nil = value
        _replaced = value
        nil
      {:error, __reason} -> nil
    end)
    parts = MyApp.NonEmptyString_Impl_.split_non_empty(test_str, " ")
    _ = Enum.each(parts, (fn -> fn _ ->
    nil
end end).())
  end
  defp test_functional_composition() do
    email_chain = MyApp.ResultTools.unwrap_or(ResultTools.map(ResultTools.map(Email_Impl_.parse("USER@EXAMPLE.COM"), fn email -> Email_Impl_.normalize(email) end), fn email -> Email_Impl_.get_domain(email) end), "unknown")
    user_id_chain = MyApp.ResultTools.unwrap_or(ResultTools.filter(ResultTools.map(UserId_Impl_.parse("TestUser123"), fn user_id -> UserId_Impl_.normalize(user_id) end), fn user_id -> UserId_Impl_.starts_with(user_id, "test") end, "UserId does not start with 'test'"), ResultTools.unwrap(UserId_Impl_.parse("defaultuser")))
    math_chain = MyApp.ResultTools.unwrap_or(ResultTools.map(ResultTools.flat_map(PositiveInt_Impl_.parse(10), fn n -> PositiveInt_Impl_.safe_sub(n, ResultTools.unwrap(PositiveInt_Impl_.parse(3))) end), fn n -> PositiveInt_Impl_.multiply(n, ResultTools.unwrap(PositiveInt_Impl_.parse(2))) end), ResultTools.unwrap(PositiveInt_Impl_.parse(1)))
    string_chain = MyApp.ResultTools.unwrap_or(ResultTools.flat_map(ResultTools.map(ResultTools.flat_map(NonEmptyString_Impl_.parse_and_trim("  hello world  "), fn s -> NonEmptyString_Impl_.safe_trim(s) end), fn s -> NonEmptyString_Impl_.to_upper_case(s) end), fn s -> NonEmptyString_Impl_.safe_replace(s, "WORLD", "UNIVERSE") end), ResultTools.unwrap(NonEmptyString_Impl_.parse("fallback")))
    composition_result = (case build_user_profile("user123", "  alice@example.com  ", "5") do
      {:ok, value} ->
        _nil = value
        nil
      {:error, __reason} -> nil
    end)
  end
  defp test_error_handling() do
    invalid_inputs = [%{:email => "invalid-email", :user_id => "ab", :score => "0"}, %{:email => "user@domain", :user_id => "user@123", :score => "-5"}, %{:email => "", :user_id => "", :score => "not-a-number"}]
    _ = Enum.each(invalid_inputs, (fn -> fn item ->
    (case build_user_profile(item.user_id, item.email, item.score) do
    {:ok, value} -> nil
    {:error, reason} ->
      nil
  end)
end end).())
    edge_cases = [%{:email => "a@b.co", :user_id => "usr", :score => "1"}, %{:email => "very.long.email.address@very.long.domain.name.example.com", :user_id => "user123456789", :score => "999"}]
    _ = Enum.each(edge_cases, (fn -> fn item ->
    (case build_user_profile(item.user_id, item.email, item.score) do
    {:ok, value} ->
      profile = value
      nil
    {:error, reason} ->
      nil
  end)
end end).())
  end
  defp test_real_world_scenarios() do
    registration_data = [%{:user_id => "alice123", :email => "alice@example.com", :preferred_name => "Alice Smith"}, %{:user_id => "bob456", :email => "bob.jones@company.org", :preferred_name => "Bob"}, %{:user_id => "charlie", :email => "charlie@test.dev", :preferred_name => "Charlie Brown"}]
    valid_users = []
    _ = Enum.each(registration_data, (fn -> fn item ->
    user_result = create_user(item.user_id, item.email, item.preferred_name)
  (case item do
    {:ok, value} ->
      user = value
      item = Enum.concat(item, [item])
      nil
    {:error, reason} ->
      nil
  end)
end end).())
    config_data = [%{:timeout => "30", :retries => "3", :name => "production"}, %{:timeout => "0", :retries => "5", :name => ""}, %{:timeout => "60", :retries => "-1", :name => "test"}]
    _ = Enum.each(config_data, (fn -> fn item ->
    config_result = validate_configuration(item.timeout, item.retries, item.name)
  (case item do
    {:ok, value} ->
      valid_config = value
      nil
    {:error, reason} ->
      nil
  end)
end end).())
  end
  defp build_user_profile(user_id_str, email_str, score_str) do
    MyApp.ResultTools.flat_map(ResultTools.map_error(UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), (fn -> fn user_id ->
      ResultTools.flat_map(ResultTools.map_error(Email_Impl_.parse(StringTools.ltrim(StringTools.rtrim(email_str))), fn e -> "Invalid Email: " <> e end), (fn -> fn email ->
        score_int = String.to_integer(score_str)
        if (score_int == nil), do: {:error, "Invalid score: " <> score_str}
        ResultTools.map(ResultTools.map_error(PositiveInt_Impl_.parse(score_int), fn e -> "Invalid score: " <> e end), fn score -> %{:user_id => user_id, :email => email, :score => score} end)
      end end).())
    end end).())
  end
  defp create_user(user_id_str, email_str, name_str) do
    MyApp.ResultTools.flat_map(ResultTools.map_error(UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), fn user_id -> ResultTools.flat_map(ResultTools.map_error(Email_Impl_.parse(email_str), fn e -> "Invalid Email: " <> e end), fn email -> ResultTools.map(ResultTools.map_error(NonEmptyString_Impl_.parse_and_trim(name_str), fn e -> "Invalid Name: " <> e end), fn display_name -> %{:user_id => user_id, :email => email, :display_name => display_name} end) end) end)
  end
  defp validate_configuration(timeout_str, retries_str, name_str) do
    timeout_int = String.to_integer(timeout_str)
    retries_int = String.to_integer(retries_str)
    if (Kernel.is_nil(timeout_int)), do: {:error, "Timeout must be a number: " <> timeout_str}
    if (Kernel.is_nil(retries_int)), do: {:error, "Retries must be a number: " <> retries_str}
    _ = MyApp.ResultTools.flat_map(ResultTools.map_error(PositiveInt_Impl_.parse(timeout_int), fn e -> "Invalid timeout: " <> e end), fn timeout -> ResultTools.flat_map(ResultTools.map_error(PositiveInt_Impl_.parse(retries_int), fn e -> "Invalid retries: " <> e end), fn retries -> ResultTools.map(ResultTools.map_error(NonEmptyString_Impl_.parse_and_trim(name_str), fn e -> "Invalid name: " <> e end), fn name -> %{:timeout => timeout, :retries => retries, :name => name} end) end) end)
  end
end
