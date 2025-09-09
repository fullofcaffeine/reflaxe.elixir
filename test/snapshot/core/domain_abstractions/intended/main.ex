defmodule Main do
  def main() do
    Log.trace("Testing domain abstractions with type safety...", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
    test_email_validation()
    test_user_id_validation()
    test_positive_int_arithmetic()
    test_non_empty_string_operations()
    test_functional_composition()
    test_error_handling()
    test_real_world_scenarios()
    Log.trace("Domain abstraction tests completed!", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "main"})
  end
  defp test_email_validation() do
    Log.trace("=== Email Validation Tests ===", %{:file_name => "Main.hx", :line_number => 44, :class_name => "Main", :method_name => "testEmailValidation"})
    email_result = Email_Impl_.parse("user@example.com")
    case (email_result) do
      {:ok, _} ->
        g = elem(email_result, 1)
        email = g
        domain = Email_Impl_.get_domain(email)
        local_part = Email_Impl_.get_local_part(email)
        Log.trace("Valid email - Domain: " <> domain <> ", Local: " <> local_part, %{:file_name => "Main.hx", :line_number => 52, :class_name => "Main", :method_name => "testEmailValidation"})
        is_example_domain = Email_Impl_.has_domain(email, "example.com")
        Log.trace("Is example.com domain: " <> Std.string(is_example_domain), %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "testEmailValidation"})
        normalized = Email_Impl_.normalize(email)
        Log.trace("Normalized: " <> Email_Impl_.to_string(normalized), %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "testEmailValidation"})
      {:error, _} ->
        g = elem(email_result, 1)
        reason = g
        Log.trace("Unexpected email validation failure: " <> reason, %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "testEmailValidation"})
    end
    invalid_emails = ["invalid-email", "@example.com", "user@", "user@@example.com", "", "user space@example.com"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, invalid_emails, :ok}, fn _, {acc_g, acc_invalid_emails, acc_state} -> nil end)
    email1_result = Email_Impl_.parse("Test@Example.Com")
    email2_result = Email_Impl_.parse("test@example.com")
    if (ResultTools.is_ok(email1_result) && ResultTools.is_ok(email2_result)) do
      email1 = ResultTools.unwrap(email1_result)
      email2 = ResultTools.unwrap(email2_result)
      are_equal = Email_Impl_.equals(email1, email2)
      Log.trace("Case-insensitive equality: " <> Std.string(are_equal), %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "testEmailValidation"})
    end
  end
  defp test_user_id_validation() do
    Log.trace("=== UserId Validation Tests ===", %{:file_name => "Main.hx", :line_number => 101, :class_name => "Main", :method_name => "testUserIdValidation"})
    valid_ids = ["user123", "Alice", "Bob42", "testUser"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, valid_ids, :ok}, fn _, {acc_g, acc_valid_ids, acc_state} -> nil end)
    invalid_ids = ["ab", "user@123", "user 123", "user-123", "", (
Enum.join((g = []
g1 = 0
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, :ok}, fn _, {acc_g1, acc_state} ->
  if (acc_g1 < 60) do
    _i = acc_g1 = acc_g1 + 1
    g ++ ["a"]
    {:cont, {acc_g1, acc_state}}
  else
    {:halt, {acc_g1, acc_state}}
  end
end)
g), "")
)]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {invalid_ids, g, :ok}, fn _, {acc_invalid_ids, acc_g, acc_state} -> nil end)
    id1_result = UserId_Impl_.parse("User123")
    id2_result = UserId_Impl_.parse("user123")
    if (ResultTools.is_ok(id1_result) && ResultTools.is_ok(id2_result)) do
      id1 = ResultTools.unwrap(id1_result)
      id2 = ResultTools.unwrap(id2_result)
      exact_equal = UserId_Impl_.equals(id1, id2)
      case_insensitive_equal = UserId_Impl_.equals_ignore_case(id1, id2)
      Log.trace("Exact equality: " <> Std.string(exact_equal) <> ", Case-insensitive: " <> Std.string(case_insensitive_equal), %{:file_name => "Main.hx", :line_number => 150, :class_name => "Main", :method_name => "testUserIdValidation"})
    end
  end
  defp test_positive_int_arithmetic() do
    Log.trace("=== PositiveInt Arithmetic Tests ===", %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    valid_numbers = [1, 5, 42, 100, 999]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {valid_numbers, g, :ok}, fn _, {acc_valid_numbers, acc_g, acc_state} -> nil end)
    invalid_numbers = [0, -1, -42, -100]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, invalid_numbers, :ok}, fn _, {acc_g, acc_invalid_numbers, acc_state} -> nil end)
    five = ResultTools.unwrap(PositiveInt_Impl_.parse(5))
    ten = ResultTools.unwrap(PositiveInt_Impl_.parse(10))
    g = PositiveInt_Impl_.safe_sub(five, ten)
    case (g) do
      {:ok, _} ->
        _g = elem(g, 1)
        Log.trace("ERROR: Subtraction that should fail succeeded", %{:file_name => "Main.hx", :line_number => 213, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      {:error, _} ->
        g = elem(g, 1)
        reason = g
        Log.trace("Correctly prevented invalid subtraction: " <> reason, %{:file_name => "Main.hx", :line_number => 215, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    end
    twenty = ResultTools.unwrap(PositiveInt_Impl_.parse(20))
    four = ResultTools.unwrap(PositiveInt_Impl_.parse(4))
    three = ResultTools.unwrap(PositiveInt_Impl_.parse(3))
    g = PositiveInt_Impl_.safe_div(twenty, four)
    case (g) do
      {:ok, _} ->
        g = elem(g, 1)
        result = g
        Log.trace("20 / 4 = " <> PositiveInt_Impl_.to_string(result), %{:file_name => "Main.hx", :line_number => 225, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      {:error, _} ->
        g = elem(g, 1)
        reason = g
        Log.trace("Division failed: " <> reason, %{:file_name => "Main.hx", :line_number => 227, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    end
    g = PositiveInt_Impl_.safe_div(twenty, three)
    case (g) do
      {:ok, _} ->
        g = elem(g, 1)
        result = g
        Log.trace("20 / 3 = " <> PositiveInt_Impl_.to_string(result) <> " (unexpected success)", %{:file_name => "Main.hx", :line_number => 232, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      {:error, _} ->
        g = elem(g, 1)
        reason = g
        Log.trace("20 / 3 correctly failed (not exact): " <> reason, %{:file_name => "Main.hx", :line_number => 234, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    end
  end
  defp test_non_empty_string_operations() do
    Log.trace("=== NonEmptyString Operations Tests ===", %{:file_name => "Main.hx", :line_number => 242, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    valid_strings = ["hello", "world", "test", "NonEmptyString"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, valid_strings, :ok}, fn _, {acc_g, acc_valid_strings, acc_state} -> nil end)
    invalid_strings = ["", "   ", "\t\n"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {invalid_strings, g, :ok}, fn _, {acc_invalid_strings, acc_g, acc_state} -> nil end)
    whitespace_strings = ["  hello  ", "\tworld\n", "  test  "]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {whitespace_strings, g, :ok}, fn _, {acc_whitespace_strings, acc_g, acc_state} -> nil end)
    test_str = ResultTools.unwrap(NonEmptyString_Impl_.parse("Hello World"))
    starts_with_hello = NonEmptyString_Impl_.starts_with(test_str, "Hello")
    ends_with_world = NonEmptyString_Impl_.ends_with(test_str, "World")
    contains_space = NonEmptyString_Impl_.contains(test_str, " ")
    Log.trace("String operations - Starts with \"Hello\": " <> Std.string(starts_with_hello) <> ", Ends with \"World\": " <> Std.string(ends_with_world) <> ", Contains space: " <> Std.string(contains_space), %{:file_name => "Main.hx", :line_number => 307, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    g = NonEmptyString_Impl_.safe_replace(test_str, "World", "Universe")
    case (g) do
      {:ok, _} ->
        g = elem(g, 1)
        replaced = g
        Log.trace("Replaced \"World\" with \"Universe\": " <> NonEmptyString_Impl_.to_string(replaced), %{:file_name => "Main.hx", :line_number => 312, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
      {:error, _} ->
        g = elem(g, 1)
        reason = g
        Log.trace("Replacement failed: " <> reason, %{:file_name => "Main.hx", :line_number => 314, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    end
    parts = NonEmptyString_Impl_.split_non_empty(test_str, " ")
    Log.trace("Split by space: " <> Kernel.to_string(length(parts)) <> " parts", %{:file_name => "Main.hx", :line_number => 319, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {parts, g, :ok}, fn _, {acc_parts, acc_g, acc_state} ->
  if (acc_g < length(acc_parts)) do
    part = parts[g]
    acc_g = acc_g + 1
    Log.trace("  Part: " <> NonEmptyString_Impl_.to_string(part), %{:file_name => "Main.hx", :line_number => 321, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    {:cont, {acc_parts, acc_g, acc_state}}
  else
    {:halt, {acc_parts, acc_g, acc_state}}
  end
end)
  end
  defp test_functional_composition() do
    Log.trace("=== Functional Composition Tests ===", %{:file_name => "Main.hx", :line_number => 329, :class_name => "Main", :method_name => "testFunctionalComposition"})
    email_chain = ResultTools.unwrap_or(ResultTools.map(ResultTools.map(Email_Impl_.parse("USER@EXAMPLE.COM"), fn email -> Email_Impl_.normalize(email) end), fn email -> Email_Impl_.get_domain(email) end), "unknown")
    Log.trace("Email chain result: " <> email_chain, %{:file_name => "Main.hx", :line_number => 336, :class_name => "Main", :method_name => "testFunctionalComposition"})
    user_id_chain = ResultTools.unwrap_or(ResultTools.filter(ResultTools.map(UserId_Impl_.parse("TestUser123"), fn user_id -> UserId_Impl_.normalize(user_id) end), fn user_id -> UserId_Impl_.starts_with(user_id, "test") end, "UserId does not start with 'test'"), ResultTools.unwrap(UserId_Impl_.parse("defaultuser")))
    Log.trace("UserId chain result: " <> UserId_Impl_.to_string(user_id_chain), %{:file_name => "Main.hx", :line_number => 343, :class_name => "Main", :method_name => "testFunctionalComposition"})
    math_chain = ResultTools.unwrap_or(ResultTools.map(ResultTools.flat_map(PositiveInt_Impl_.parse(10), fn n -> PositiveInt_Impl_.safe_sub(n, ResultTools.unwrap(PositiveInt_Impl_.parse(3))) end), fn n -> PositiveInt_Impl_.multiply(n, ResultTools.unwrap(PositiveInt_Impl_.parse(2))) end), ResultTools.unwrap(PositiveInt_Impl_.parse(1)))
    Log.trace("Math chain result: " <> PositiveInt_Impl_.to_string(math_chain), %{:file_name => "Main.hx", :line_number => 350, :class_name => "Main", :method_name => "testFunctionalComposition"})
    string_chain = ResultTools.unwrap_or(ResultTools.flat_map(ResultTools.map(ResultTools.flat_map(NonEmptyString_Impl_.parse_and_trim("  hello world  "), fn s -> NonEmptyString_Impl_.safe_trim(s) end), fn s -> NonEmptyString_Impl_.to_upper_case(s) end), fn s -> NonEmptyString_Impl_.safe_replace(s, "WORLD", "UNIVERSE") end), ResultTools.unwrap(NonEmptyString_Impl_.parse("fallback")))
    Log.trace("String chain result: " <> NonEmptyString_Impl_.to_string(string_chain), %{:file_name => "Main.hx", :line_number => 358, :class_name => "Main", :method_name => "testFunctionalComposition"})
    composition_result = build_user_profile("user123", "  alice@example.com  ", "5")
    case (composition_result) do
      {:ok, _} ->
        g = elem(composition_result, 1)
        profile = g
        Log.trace("User profile created successfully:", %{:file_name => "Main.hx", :line_number => 364, :class_name => "Main", :method_name => "testFunctionalComposition"})
        Log.trace("  UserId: " <> UserId_Impl_.to_string(profile.user_id), %{:file_name => "Main.hx", :line_number => 365, :class_name => "Main", :method_name => "testFunctionalComposition"})
        Log.trace("  Email: " <> Email_Impl_.to_string(profile.email), %{:file_name => "Main.hx", :line_number => 366, :class_name => "Main", :method_name => "testFunctionalComposition"})
        Log.trace("  Score: " <> PositiveInt_Impl_.to_string(profile.score), %{:file_name => "Main.hx", :line_number => 367, :class_name => "Main", :method_name => "testFunctionalComposition"})
      {:error, _} ->
        g = elem(composition_result, 1)
        reason = g
        Log.trace("User profile creation failed: " <> reason, %{:file_name => "Main.hx", :line_number => 369, :class_name => "Main", :method_name => "testFunctionalComposition"})
    end
  end
  defp test_error_handling() do
    Log.trace("=== Error Handling Tests ===", %{:file_name => "Main.hx", :line_number => 377, :class_name => "Main", :method_name => "testErrorHandling"})
    invalid_inputs = [%{:email => "invalid-email", :user_id => "ab", :score => "0"}, %{:email => "user@domain", :user_id => "user@123", :score => "-5"}, %{:email => "", :user_id => "", :score => "not-a-number"}]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, invalid_inputs, :ok}, fn _, {acc_g, acc_invalid_inputs, acc_state} -> nil end)
    Log.trace("Testing edge cases that should succeed:", %{:file_name => "Main.hx", :line_number => 396, :class_name => "Main", :method_name => "testErrorHandling"})
    edge_cases = [%{:email => "a@b.co", :user_id => "usr", :score => "1"}, %{:email => "very.long.email.address@very.long.domain.name.example.com", :user_id => "user123456789", :score => "999"}]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {edge_cases, g, :ok}, fn _, {acc_edge_cases, acc_g, acc_state} -> nil end)
  end
  defp test_real_world_scenarios() do
    Log.trace("=== Real-World Scenarios ===", %{:file_name => "Main.hx", :line_number => 417, :class_name => "Main", :method_name => "testRealWorldScenarios"})
    registration_data = [%{:user_id => "alice123", :email => "alice@example.com", :preferred_name => "Alice Smith"}, %{:user_id => "bob456", :email => "bob.jones@company.org", :preferred_name => "Bob"}, %{:user_id => "charlie", :email => "charlie@test.dev", :preferred_name => "Charlie Brown"}]
    valid_users = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {registration_data, g, :ok}, fn _, {acc_registration_data, acc_g, acc_state} ->
  if (acc_g < length(acc_registration_data)) do
    user_data = registration_data[g]
    acc_g = acc_g + 1
    user_result = create_user(user_data.user_id, user_data.email, user_data.preferred_name)
    nil
    {:cont, {acc_registration_data, acc_g, acc_state}}
  else
    {:halt, {acc_registration_data, acc_g, acc_state}}
  end
end)
    Log.trace("Successfully created " <> Kernel.to_string(length(valid_users)) <> " users", %{:file_name => "Main.hx", :line_number => 439, :class_name => "Main", :method_name => "testRealWorldScenarios"})
    config_data = [%{:timeout => "30", :retries => "3", :name => "production"}, %{:timeout => "0", :retries => "5", :name => ""}, %{:timeout => "60", :retries => "-1", :name => "test"}]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, config_data, :ok}, fn _, {acc_g, acc_config_data, acc_state} ->
  if (acc_g < length(acc_config_data)) do
    config = config_data[g]
    acc_g = acc_g + 1
    config_result = validate_configuration(config.timeout, config.retries, config.name)
    nil
    {:cont, {acc_g, acc_config_data, acc_state}}
  else
    {:halt, {acc_g, acc_config_data, acc_state}}
  end
end)
  end
  defp build_user_profile(user_id_str, _email_str, _score_str) do
    ResultTools.flat_map(ResultTools.map_error(UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), fn _user_id ->
  ResultTools.flat_map(ResultTools.map_error(Email_Impl_.parse(StringTools.ltrim(StringTools.rtrim(_email_str))), fn e -> "Invalid Email: " <> e end), fn _email ->
  score_int = Std.parse_int(_score_str)
  if (score_int == nil), do: {:error, "Invalid score: " <> _score_str}
  ResultTools.map(ResultTools.map_error(PositiveInt_Impl_.parse(score_int), fn e -> "Invalid score: " <> e end), fn score -> %{:user_id => _user_id, :email => _email, :score => score} end)
end)
end)
  end
  defp create_user(user_id_str, _email_str, _name_str) do
    ResultTools.flat_map(ResultTools.map_error(UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), fn _user_id -> ResultTools.flat_map(ResultTools.map_error(Email_Impl_.parse(_email_str), fn e -> "Invalid Email: " <> e end), fn _email -> ResultTools.map(ResultTools.map_error(NonEmptyString_Impl_.parse_and_trim(_name_str), fn e -> "Invalid Name: " <> e end), fn display_name -> %{:user_id => _user_id, :email => _email, :display_name => display_name} end) end) end)
  end
  defp validate_configuration(timeout_str, retries_str, _name_str) do
    timeout_int = Std.parse_int(timeout_str)
    retries_int = Std.parse_int(retries_str)
    if (timeout_int == nil), do: {:error, "Timeout must be a number: " <> timeout_str}
    if (retries_int == nil), do: {:error, "Retries must be a number: " <> retries_str}
    ResultTools.flat_map(ResultTools.map_error(PositiveInt_Impl_.parse(timeout_int), fn e -> "Invalid timeout: " <> e end), fn _timeout -> ResultTools.flat_map(ResultTools.map_error(PositiveInt_Impl_.parse(retries_int), fn e -> "Invalid retries: " <> e end), fn _retries -> ResultTools.map(ResultTools.map_error(NonEmptyString_Impl_.parse_and_trim(_name_str), fn e -> "Invalid name: " <> e end), fn name -> %{:timeout => _timeout, :retries => _retries, :name => name} end) end) end)
  end
end

Code.require_file("haxe/validation/_user_id/user_id_impl_.ex", __DIR__)
Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/functional/result_tools.ex", __DIR__)
Code.require_file("haxe/validation/_positive_int/positive_int_impl_.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("haxe/validation/_email/email_impl_.ex", __DIR__)
Code.require_file("string_tools.ex", __DIR__)
Code.require_file("haxe/validation/_non_empty_string/non_empty_string_impl_.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()