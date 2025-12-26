defmodule Main do
  defp test_email_validation() do
    email_result = (case MyApp.Email_Impl_.parse("user@example.com") do
      {:ok, email} ->
        domain = email.get_domain(email)
        local_part = email.get_local_part(email)
        is_example_domain = email.has_domain(email, "example.com")
        normalized = email.normalize(email)
        nil
      {:error, _error} -> nil
    end)
    invalid_emails = ["invalid-email", "@example.com", "user@", "user@@example.com", "", "user space@example.com"]
    _g = 0
    _ = Enum.each(invalid_emails, (fn -> fn invalid_email ->
  (case invalid_email.parse(invalid_email) do
    {:ok, _value} -> nil
    {:error, _error} -> nil
  end)
end end).())
    email1_result = MyApp.Email_Impl_.parse("Test@Example.Com")
    email2_result = MyApp.Email_Impl_.parse("test@example.com")
    if (MyApp.ResultTools.is_ok(email1_result) and MyApp.ResultTools.is_ok(email2_result)) do
      email1 = MyApp.ResultTools.unwrap(email1_result)
      email2 = MyApp.ResultTools.unwrap(email2_result)
      are_equal = MyApp.Email_Impl_.equals(email1, email2)
      nil
    end
  end
  defp test_user_id_validation() do
    valid_ids = ["user123", "Alice", "Bob42", "testUser"]
    _g = 0
    _ = Enum.each(valid_ids, (fn -> fn valid_id ->
  (case valid_id.parse(valid_id) do
    {:ok, user_id} ->
      length = user_id.length(user_id)
      normalized = user_id.normalize(user_id)
      starts_with_user = user_id.starts_with_ignore_case(user_id, "user")
      nil
    {:error, _error} -> nil
  end)
end end).())
    invalid_ids = ["ab", "user@123", "user 123", "user-123", "", Enum.join((fn ->
  (fn ->
  g = 0
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, (fn -> fn _, {g} ->
    if (g < 60) do
      old__g1 = g
      _g = g + 1
      i = old__g1
      _ = ["a"]
      {:cont, {g}}
    else
      {:halt, {g}}
    end
  end end).())
  nil
  []
end).()
end).(), "")]
    _g = 0
    _ = Enum.each(invalid_ids, (fn -> fn invalid_id ->
  (case invalid_id.parse(invalid_id) do
    {:ok, _value} -> nil
    {:error, _error} -> nil
  end)
end end).())
    id1_result = MyApp.UserId_Impl_.parse("User123")
    id2_result = MyApp.UserId_Impl_.parse("user123")
    if (MyApp.ResultTools.is_ok(id1_result) and MyApp.ResultTools.is_ok(id2_result)) do
      id1 = MyApp.ResultTools.unwrap(id1_result)
      id2 = MyApp.ResultTools.unwrap(id2_result)
      exact_equal = MyApp.UserId_Impl_.equals(id1, id2)
      case_insensitive_equal = MyApp.UserId_Impl_.equals_ignore_case(id1, id2)
      nil
    end
  end
  defp test_positive_int_arithmetic() do
    valid_numbers = [1, 5, 42, 100, 999]
    _g = 0
    _ = Enum.each(valid_numbers, (fn -> fn valid_num ->
  (case valid_num.parse(valid_num) do
    {:ok, pos_int} ->
      doubled = pos_int.multiply(pos_int, pos_int.unwrap(pos_int.parse(2)))
      added = pos_int.add(pos_int, pos_int.unwrap(pos_int.parse(10)))
      subtract_result = pos_int.safe_sub(pos_int, pos_int.unwrap(pos_int.parse(1)))
      (case subtract_result do
        {:ok, _result} -> nil
        {:error, _error} -> nil
      end)
      five = pos_int.unwrap(pos_int.parse(5))
      is_greater = pos_int.greater_than(pos_int, five)
      min = pos_int.min(pos_int, five)
      max = pos_int.max(pos_int, five)
      nil
    {:error, _error} -> nil
  end)
end end).())
    invalid_numbers = [0, -1, -42, -100]
    _g = 0
    _ = Enum.each(invalid_numbers, (fn -> fn invalid_num ->
  (case invalid_num.parse(invalid_num) do
    {:ok, _value} -> nil
    {:error, _error} -> nil
  end)
end end).())
    five = MyApp.ResultTools.unwrap(MyApp.PositiveInt_Impl_.parse(5))
    ten = MyApp.ResultTools.unwrap(MyApp.PositiveInt_Impl_.parse(10))
    (case MyApp.PositiveInt_Impl_.safe_sub(five, ten) do
      {:ok, _value} -> nil
      {:error, _error} -> nil
    end)
    twenty = MyApp.ResultTools.unwrap(MyApp.PositiveInt_Impl_.parse(20))
    four = MyApp.ResultTools.unwrap(MyApp.PositiveInt_Impl_.parse(4))
    three = MyApp.ResultTools.unwrap(MyApp.PositiveInt_Impl_.parse(3))
    (case MyApp.PositiveInt_Impl_.safe_div(twenty, four) do
      {:ok, _result} -> nil
      {:error, _error} -> nil
    end)
    (case MyApp.PositiveInt_Impl_.safe_div(twenty, three) do
      {:ok, _result} -> nil
      {:error, _error} -> nil
    end)
  end
  defp test_non_empty_string_operations() do
    valid_strings = ["hello", "world", "test", "NonEmptyString"]
    _g = 0
    _ = Enum.each(valid_strings, (fn -> fn valid_str ->
  (case valid_str.parse(valid_str) do
    {:ok, non_empty_str} ->
      length = non_empty_str.length(non_empty_str)
      upper = non_empty_str.to_upper_case(non_empty_str)
      lower = non_empty_str.to_lower_case(non_empty_str)
      other = non_empty_str.unwrap(non_empty_str.parse("!"))
      concatenated = non_empty_str.concat(non_empty_str, non_empty_str)
      first_char = non_empty_str.first_char(non_empty_str)
      last_char = non_empty_str.last_char(non_empty_str)
      (case non_empty_str.safe_substring(non_empty_str, 1) do
        {:ok, _substr} -> nil
        {:error, _error} -> nil
      end)
    {:error, _error} -> nil
  end)
end end).())
    invalid_strings = ["", "   ", "\t\n"]
    _g = 0
    _ = Enum.each(invalid_strings, (fn -> fn invalid_str ->
  (case invalid_str.parse(invalid_str) do
    {:ok, _value} -> nil
    {:error, _error} -> nil
  end)
end end).())
    whitespace_strings = ["  hello  ", "\tworld\n", "  test  "]
    _g = 0
    _ = Enum.each(whitespace_strings, (fn -> fn whitespace_str ->
  (case whitespace_str.parse_and_trim(whitespace_str) do
    {:ok, _trimmed} -> nil
    {:error, _error} -> nil
  end)
end end).())
    test_str = MyApp.ResultTools.unwrap(MyApp.NonEmptyString_Impl_.parse("Hello World"))
    starts_with_hello = MyApp.NonEmptyString_Impl_.starts_with(test_str, "Hello")
    ends_with_world = MyApp.NonEmptyString_Impl_.ends_with(test_str, "World")
    contains_space = MyApp.NonEmptyString_Impl_.contains(test_str, " ")
    (case MyApp.NonEmptyString_Impl_.safe_replace(test_str, "World", "Universe") do
      {:ok, _replaced} -> nil
      {:error, _error} -> nil
    end)
    parts = MyApp.NonEmptyString_Impl_.split_non_empty(test_str, " ")
    _g = 0
    _ = Enum.each(parts, fn _ -> nil end)
  end
  defp test_functional_composition() do
    email_chain = MyApp.ResultTools.unwrap_or(MyApp.ResultTools.map(MyApp.ResultTools.map(MyApp.Email_Impl_.parse("USER@EXAMPLE.COM"), fn email -> MyApp.Email_Impl_.normalize(email) end), fn email -> MyApp.Email_Impl_.get_domain(email) end), "unknown")
    user_id_chain = MyApp.ResultTools.unwrap_or(MyApp.ResultTools.filter(MyApp.ResultTools.map(MyApp.UserId_Impl_.parse("TestUser123"), fn user_id -> MyApp.UserId_Impl_.normalize(user_id) end), fn user_id -> MyApp.UserId_Impl_.starts_with(user_id, "test") end, "UserId does not start with 'test'"), MyApp.ResultTools.unwrap(MyApp.UserId_Impl_.parse("defaultuser")))
    math_chain = MyApp.ResultTools.unwrap_or(MyApp.ResultTools.map(MyApp.ResultTools.flat_map(MyApp.PositiveInt_Impl_.parse(10), fn n -> MyApp.PositiveInt_Impl_.safe_sub(n, MyApp.ResultTools.unwrap(MyApp.PositiveInt_Impl_.parse(3))) end), fn n -> MyApp.PositiveInt_Impl_.multiply(n, MyApp.ResultTools.unwrap(MyApp.PositiveInt_Impl_.parse(2))) end), MyApp.ResultTools.unwrap(MyApp.PositiveInt_Impl_.parse(1)))
    string_chain = MyApp.ResultTools.unwrap_or(MyApp.ResultTools.flat_map(MyApp.ResultTools.map(MyApp.ResultTools.flat_map(MyApp.NonEmptyString_Impl_.parse_and_trim("  hello world  "), fn s -> MyApp.NonEmptyString_Impl_.safe_trim(s) end), fn s -> MyApp.NonEmptyString_Impl_.to_upper_case(s) end), fn s -> MyApp.NonEmptyString_Impl_.safe_replace(s, "WORLD", "UNIVERSE") end), MyApp.ResultTools.unwrap(MyApp.NonEmptyString_Impl_.parse("fallback")))
    composition_result = (case build_user_profile("user123", "  alice@example.com  ", "5") do
      {:ok, _profile} -> nil
      {:error, _error} -> nil
    end)
  end
  defp test_error_handling() do
    invalid_inputs = [%{:email => "invalid-email", :user_id => "ab", :score => "0"}, %{:email => "user@domain", :user_id => "user@123", :score => "-5"}, %{:email => "", :user_id => "", :score => "not-a-number"}]
    _g = 0
    _ = Enum.each(invalid_inputs, (fn -> fn input ->
  (case build_user_profile(input.user_id, input.email, input.score) do
    {:ok, _value} -> nil
    {:error, _error} -> nil
  end)
end end).())
    edge_cases = [%{:email => "a@b.co", :user_id => "usr", :score => "1"}, %{:email => "very.long.email.address@very.long.domain.name.example.com", :user_id => "user123456789", :score => "999"}]
    _g = 0
    _ = Enum.each(edge_cases, (fn -> fn edge_case ->
  (case build_user_profile(edge_case.user_id, edge_case.email, edge_case.score) do
    {:ok, _profile} -> nil
    {:error, _error} -> nil
  end)
end end).())
  end
  defp test_real_world_scenarios() do
    registration_data = [%{:user_id => "alice123", :email => "alice@example.com", :preferred_name => "Alice Smith"}, %{:user_id => "bob456", :email => "bob.jones@company.org", :preferred_name => "Bob"}, %{:user_id => "charlie", :email => "charlie@test.dev", :preferred_name => "Charlie Brown"}]
    valid_users = []
    _g = 0
    _ = Enum.each(registration_data, (fn -> fn user_data ->
  user_result = create_user(user_data.user_id, user_data.email, user_data.preferred_name)
  (case user_result do
    {:ok, user} ->
      _ = user ++ [user]
      nil
    {:error, _error} -> nil
  end)
end end).())
    config_data = [%{:timeout => "30", :retries => "3", :name => "production"}, %{:timeout => "0", :retries => "5", :name => ""}, %{:timeout => "60", :retries => "-1", :name => "test"}]
    _g = 0
    _ = Enum.each(config_data, (fn -> fn config ->
  config_result = validate_configuration(config.timeout, config.retries, config.name)
  (case config_result do
    {:ok, _valid_config} -> nil
    {:error, _error} -> nil
  end)
end end).())
  end
  defp build_user_profile(user_id_str, email_str, score_str) do
    MyApp.ResultTools.flat_map(MyApp.ResultTools.map_error(MyApp.UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), (fn -> fn user_id ->
      MyApp.ResultTools.flat_map(MyApp.ResultTools.map_error(MyApp.Email_Impl_.parse(StringTools.ltrim(StringTools.rtrim(email_str))), fn e -> "Invalid Email: " <> e end), (fn -> fn email ->
        score_int = ((case Integer.parse(score_str) do
  {num, _} -> num
  :error -> nil
end))
        if (Kernel.is_nil(score_int)) do
          {:error, "Invalid score: " <> score_str}
        else
          MyApp.ResultTools.map(MyApp.ResultTools.map_error(MyApp.PositiveInt_Impl_.parse(score_int), fn e -> "Invalid score: " <> e end), fn score -> %{:user_id => user_id, :email => email, :score => score} end)
        end
      end end).())
    end end).())
  end
  defp create_user(user_id_str, email_str, name_str) do
    MyApp.ResultTools.flat_map(MyApp.ResultTools.map_error(MyApp.UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), fn user_id -> MyApp.ResultTools.flat_map(MyApp.ResultTools.map_error(MyApp.Email_Impl_.parse(email_str), fn e -> "Invalid Email: " <> e end), fn email -> MyApp.ResultTools.map(MyApp.ResultTools.map_error(MyApp.NonEmptyString_Impl_.parse_and_trim(name_str), fn e -> "Invalid Name: " <> e end), fn display_name -> %{:user_id => user_id, :email => email, :display_name => display_name} end) end) end)
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
        MyApp.ResultTools.flat_map(MyApp.ResultTools.map_error(MyApp.PositiveInt_Impl_.parse(timeout_int), fn e -> "Invalid timeout: " <> e end), fn timeout -> MyApp.ResultTools.flat_map(MyApp.ResultTools.map_error(MyApp.PositiveInt_Impl_.parse(retries_int), fn e -> "Invalid retries: " <> e end), fn retries -> MyApp.ResultTools.map(MyApp.ResultTools.map_error(MyApp.NonEmptyString_Impl_.parse_and_trim(name_str), fn e -> "Invalid name: " <> e end), fn name -> %{:timeout => timeout, :retries => retries, :name => name} end) end) end)
      end
    end
  end
end
