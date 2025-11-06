defmodule Main do
  defp test_email_validation() do
    _ = Log.trace("=== Email Validation Tests ===", %{:file_name => "Main.hx", :line_number => 45, :class_name => "Main", :method_name => "testEmailValidation"})
    parsed_result = MyApp.Email_Impl_.parse("user@example.com")
    (case parsed_result do
      {:ok, value} ->
        normalized = value
        to_string = value
        _ = value
        _ = Log.trace("Valid email - Domain: #{(fn -> domain end).()}, Local: #{(fn -> localPart end).()}", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "testEmailValidation"})
        _ = Log.trace("Is example.com domain: #{(fn -> inspect(isExampleDomain) end).()}", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "testEmailValidation"})
        _ = Log.trace("Normalized: #{(fn -> Email_Impl_.to_string(normalized) end).()}", %{:file_name => "Main.hx", :line_number => 61, :class_name => "Main", :method_name => "testEmailValidation"})
      {:error, reason} ->
        Log.trace("Unexpected email validation failure: #{(fn -> reason end).()}", %{:file_name => "Main.hx", :line_number => 64, :class_name => "Main", :method_name => "testEmailValidation"})
    end)
    _ = ["invalid-email", "@example.com", "user@", "user@@example.com", "", "user space@example.com"]
    _ = Enum.each(invalid_emails, (fn -> fn item ->
    (case Email_Impl_.parse(invalid_email) do
    {:ok, invalid_email} ->
      Log.trace("ERROR: Invalid email \"" <> item <> "\" was accepted", %{:file_name => "Main.hx", :line_number => 80, :class_name => "Main", :method_name => "testEmailValidation"})
    {:error, reason} ->
      Log.trace("Correctly rejected \"" <> item <> "\": " <> reason, %{:file_name => "Main.hx", :line_number => 82, :class_name => "Main", :method_name => "testEmailValidation"})
  end)
end end).())
    _ = MyApp.Email_Impl_.parse("Test@Example.Com")
    _ = MyApp.Email_Impl_.parse("test@example.com")
    if (MyApp.ResultTools.is_ok(email1_result) and MyApp.ResultTools.is_ok(email2_result)) do
      _ = MyApp.ResultTools.unwrap(email1_result)
      _ = MyApp.ResultTools.unwrap(email2_result)
      _ = MyApp.Email_Impl_.equals(email1, email2)
      _ = Log.trace("Case-insensitive equality: #{(fn -> inspect(are_equal) end).()}", %{:file_name => "Main.hx", :line_number => 94, :class_name => "Main", :method_name => "testEmailValidation"})
    end
  end
  defp test_user_id_validation() do
    _ = Log.trace("=== UserId Validation Tests ===", %{:file_name => "Main.hx", :line_number => 102, :class_name => "Main", :method_name => "testUserIdValidation"})
    _ = ["user123", "Alice", "Bob42", "testUser"]
    _ = Enum.each(valid_ids, (fn -> fn item ->
    (case UserId_Impl_.parse(item) do
    {:ok, value} ->
      user_id = value
      Log.trace("Valid UserId \"" <> validId <> "\" - Length: " <> Kernel.to_string(length) <> ", Normalized: " <> UserId_Impl_.to_string(normalized), %{:file_name => "Main.hx", :line_number => 112, :class_name => "Main", :method_name => "testUserIdValidation"})
      Log.trace("Starts with \"user\" (case-insensitive): " <> inspect(startsWithUser), %{:file_name => "Main.hx", :line_number => 116, :class_name => "Main", :method_name => "testUserIdValidation"})
    {:error, reason} ->
      Log.trace("Unexpected UserId validation failure for \"" <> validId <> "\": " <> reason, %{:file_name => "Main.hx", :line_number => 119, :class_name => "Main", :method_name => "testUserIdValidation"})
  end)
end end).())
    _ = ["ab", "user@123", "user 123", "user-123", "", Enum.join((fn ->
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
    (case UserId_Impl_.parse(invalid_id) do
    {:ok, invalid_id} ->
      Log.trace("ERROR: Invalid UserId \"" <> item <> "\" was accepted", %{:file_name => "Main.hx", :line_number => 136, :class_name => "Main", :method_name => "testUserIdValidation"})
    {:error, reason} ->
      Log.trace("Correctly rejected \"" <> item <> "\": " <> reason, %{:file_name => "Main.hx", :line_number => 138, :class_name => "Main", :method_name => "testUserIdValidation"})
  end)
end end).())
    _ = MyApp.UserId_Impl_.parse("User123")
    _ = MyApp.UserId_Impl_.parse("user123")
    if (MyApp.ResultTools.is_ok(id1_result) and MyApp.ResultTools.is_ok(id2_result)) do
      _ = MyApp.ResultTools.unwrap(id1_result)
      _ = MyApp.ResultTools.unwrap(id2_result)
      _ = MyApp.UserId_Impl_.equals(id1, id2)
      _ = MyApp.UserId_Impl_.equals_ignore_case(id1, id2)
      _ = Log.trace("Exact equality: #{(fn -> inspect(exact_equal) end).()}, Case-insensitive: #{(fn -> inspect(case_insensitive_equal) end).()}", %{:file_name => "Main.hx", :line_number => 151, :class_name => "Main", :method_name => "testUserIdValidation"})
    end
  end
  defp test_positive_int_arithmetic() do
    _ = Log.trace("=== PositiveInt Arithmetic Tests ===", %{:file_name => "Main.hx", :line_number => 159, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    _ = [1, 5, 42, 100, 999]
    _ = Enum.each(valid_numbers, (fn -> fn item ->
    (case PositiveInt_Impl_.parse(item) do
    {:ok, value} ->
      pos_int = value
      Log.trace("Valid PositiveInt: " <> PositiveInt_Impl_.to_string(pos_int), %{:file_name => "Main.hx", :line_number => 167, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      doubled = PositiveInt_Impl_.multiply(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(2)))
      added = PositiveInt_Impl_.add(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(10)))
      Log.trace("Doubled: " <> PositiveInt_Impl_.to_string(doubled) <> ", Added 10: " <> PositiveInt_Impl_.to_string(added), %{:file_name => "Main.hx", :line_number => 172, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      subtract_result = PositiveInt_Impl_.safe_sub(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(1)))
      (case item do
        {:ok, value} ->
          Log.trace("Safe subtraction result: " <> PositiveInt_Impl_.to_string(result), %{:file_name => "Main.hx", :line_number => 178, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
        {:error, reason} ->
          Log.trace("Safe subtraction failed: " <> reason, %{:file_name => "Main.hx", :line_number => 180, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      end)
      five = ResultTools.unwrap(PositiveInt_Impl_.parse(5))
      is_greater = PositiveInt_Impl_.greater_than(pos_int, five)
      min = PositiveInt_Impl_.min(pos_int, five)
      max = PositiveInt_Impl_.max(pos_int, five)
      Log.trace("Greater than 5: " <> inspect(is_greater) <> ", Min with 5: " <> PositiveInt_Impl_.to_string(min) <> ", Max with 5: " <> PositiveInt_Impl_.to_string(max), %{:file_name => "Main.hx", :line_number => 188, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    {:error, reason} ->
      Log.trace("Unexpected PositiveInt validation failure for " <> Kernel.to_string(validNum) <> ": " <> reason, %{:file_name => "Main.hx", :line_number => 191, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
  end)
end end).())
    _ = [0, -1, -42, -100]
    _ = Enum.each(invalid_numbers, (fn -> fn item ->
    (case PositiveInt_Impl_.parse(invalid_num) do
    {:ok, invalid_num} ->
      Log.trace("ERROR: Invalid PositiveInt " <> Kernel.to_string(item) <> " was accepted", %{:file_name => "Main.hx", :line_number => 201, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    {:error, reason} ->
      Log.trace("Correctly rejected " <> Kernel.to_string(item) <> ": " <> reason, %{:file_name => "Main.hx", :line_number => 203, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
  end)
end end).())
    _ = MyApp.ResultTools.unwrap(PositiveInt_Impl_.parse(5))
    _ = MyApp.ResultTools.unwrap(PositiveInt_Impl_.parse(10))
    (case MyApp.PositiveInt_Impl_.safe_sub(five, ten) do
      {:ok, _value} ->
        Log.trace("ERROR: Subtraction that should fail succeeded", %{:file_name => "Main.hx", :line_number => 214, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      {:error, reason} ->
        Log.trace("Correctly prevented invalid subtraction: #{(fn -> reason end).()}", %{:file_name => "Main.hx", :line_number => 216, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    end)
    _ = MyApp.ResultTools.unwrap(PositiveInt_Impl_.parse(20))
    _ = MyApp.ResultTools.unwrap(PositiveInt_Impl_.parse(4))
    _ = MyApp.ResultTools.unwrap(PositiveInt_Impl_.parse(3))
    (case MyApp.PositiveInt_Impl_.safe_div(twenty, four) do
      {:ok, _value} ->
        result = _value
        to_string = _value
        Log.trace("20 / 4 = #{(fn -> PositiveInt_Impl_.to_string(result) end).()}", %{:file_name => "Main.hx", :line_number => 226, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      {:error, reason} ->
        Log.trace("Division failed: #{(fn -> reason end).()}", %{:file_name => "Main.hx", :line_number => 228, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    end)
    (case MyApp.PositiveInt_Impl_.safe_div(twenty, three) do
      {:ok, _value} ->
        result = _value
        to_string = _value
        Log.trace("20 / 3 = #{(fn -> PositiveInt_Impl_.to_string(result) end).()} (unexpected success)", %{:file_name => "Main.hx", :line_number => 233, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      {:error, reason} ->
        Log.trace("20 / 3 correctly failed (not exact): #{(fn -> reason end).()}", %{:file_name => "Main.hx", :line_number => 235, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    end)
  end
  defp test_non_empty_string_operations() do
    _ = Log.trace("=== NonEmptyString Operations Tests ===", %{:file_name => "Main.hx", :line_number => 243, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    _ = ["hello", "world", "test", "NonEmptyString"]
    _ = Enum.each(valid_strings, (fn -> fn item ->
    (case NonEmptyString_Impl_.parse(item) do
    {:ok, value} ->
      non_empty_str = value
      Log.trace("Valid NonEmptyString \"" <> validStr <> "\" - Length: " <> Kernel.to_string(length) <> ", Upper: " <> NonEmptyString_Impl_.to_string(upper) <> ", Lower: " <> NonEmptyString_Impl_.to_string(lower), %{:file_name => "Main.hx", :line_number => 254, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
      other = ResultTools.unwrap(NonEmptyString_Impl_.parse("!"))
      Log.trace("Concatenated with \"!\": " <> NonEmptyString_Impl_.to_string(concatenated), %{:file_name => "Main.hx", :line_number => 259, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
      Log.trace("First char: " <> NonEmptyString_Impl_.to_string(firstChar) <> ", Last char: " <> NonEmptyString_Impl_.to_string(lastChar), %{:file_name => "Main.hx", :line_number => 264, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
      (case NonEmptyString_Impl_.safe_substring(non_empty_str, 1) do
        {:ok, value} ->
          Log.trace("Substring from index 1: " <> NonEmptyString_Impl_.to_string(substr), %{:file_name => "Main.hx", :line_number => 269, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
        {:error, reason} ->
          Log.trace("Substring failed: " <> reason, %{:file_name => "Main.hx", :line_number => 271, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
      end)
    {:error, reason} ->
      Log.trace("Unexpected NonEmptyString validation failure for \"" <> validStr <> "\": " <> reason, %{:file_name => "Main.hx", :line_number => 275, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
  end)
end end).())
    _ = ["", "   ", "\t\n"]
    _ = Enum.each(invalid_strings, (fn -> fn item ->
    (case NonEmptyString_Impl_.parse(invalid_str) do
    {:ok, invalid_str} ->
      Log.trace("ERROR: Invalid NonEmptyString \"" <> item <> "\" was accepted", %{:file_name => "Main.hx", :line_number => 285, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    {:error, reason} ->
      Log.trace("Correctly rejected \"" <> item <> "\": " <> reason, %{:file_name => "Main.hx", :line_number => 287, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
  end)
end end).())
    _ = ["  hello  ", "\tworld\n", "  test  "]
    _ = Enum.each(whitespace_strings, (fn -> fn item ->
    (case NonEmptyString_Impl_.parse_and_trim(item) do
    {:ok, value} ->
      Log.trace("Trimmed \"" <> whitespaceStr <> "\" to \"" <> NonEmptyString_Impl_.to_string(trimmed) <> "\"", %{:file_name => "Main.hx", :line_number => 297, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    {:error, reason} ->
      Log.trace("Trim and parse failed for \"" <> whitespaceStr <> "\": " <> reason, %{:file_name => "Main.hx", :line_number => 299, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
  end)
end end).())
    _ = MyApp.ResultTools.unwrap(NonEmptyString_Impl_.parse("Hello World"))
    _ = MyApp.NonEmptyString_Impl_.starts_with(test_str, "Hello")
    _ = MyApp.NonEmptyString_Impl_.ends_with(test_str, "World")
    _ = MyApp.NonEmptyString_Impl_.contains(test_str, " ")
    _ = Log.trace("String operations - Starts with \"Hello\": #{(fn -> inspect(starts_with_hello) end).()}, Ends with \"World\": #{(fn -> inspect(ends_with_world) end).()}, Contains space: #{(fn -> inspect(contains_space) end).()}", %{:file_name => "Main.hx", :line_number => 308, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    (case MyApp.NonEmptyString_Impl_.safe_replace(test_str, "World", "Universe") do
      {:ok, _value} ->
        replaced = _value
        to_string = _value
        Log.trace("Replaced \"World\" with \"Universe\": #{(fn -> NonEmptyString_Impl_.to_string(replaced) end).()}", %{:file_name => "Main.hx", :line_number => 313, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
      {:error, reason} ->
        Log.trace("Replacement failed: #{(fn -> reason end).()}", %{:file_name => "Main.hx", :line_number => 315, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    end)
    _ = MyApp.NonEmptyString_Impl_.split_non_empty(test_str, " ")
    _ = Log.trace("Split by space: #{(fn -> length(parts) end).()} parts", %{:file_name => "Main.hx", :line_number => 320, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    _ = Enum.each(parts, (fn -> fn item ->
    Log.trace("  Part: " <> NonEmptyString_Impl_.to_string(item), %{:file_name => "Main.hx", :line_number => 322, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
end end).())
    _
  end
  defp test_functional_composition() do
    _ = Log.trace("=== Functional Composition Tests ===", %{:file_name => "Main.hx", :line_number => 330, :class_name => "Main", :method_name => "testFunctionalComposition"})
    _ = MyApp.ResultTools.unwrap_or(ResultTools.map(ResultTools.map(Email_Impl_.parse("USER@EXAMPLE.COM"), fn email -> Email_Impl_.normalize(email) end), fn email -> Email_Impl_.get_domain(email) end), "unknown")
    _ = Log.trace("Email chain result: #{(fn -> email_chain end).()}", %{:file_name => "Main.hx", :line_number => 337, :class_name => "Main", :method_name => "testFunctionalComposition"})
    _ = MyApp.ResultTools.unwrap_or(ResultTools.filter(ResultTools.map(UserId_Impl_.parse("TestUser123"), fn user_id -> UserId_Impl_.normalize(user_id) end), fn user_id -> UserId_Impl_.starts_with(user_id, "test") end, "UserId does not start with 'test'"), ResultTools.unwrap(UserId_Impl_.parse("defaultuser")))
    _ = Log.trace("UserId chain result: #{(fn -> UserId_Impl_.to_string(user_id_chain) end).()}", %{:file_name => "Main.hx", :line_number => 344, :class_name => "Main", :method_name => "testFunctionalComposition"})
    _ = MyApp.ResultTools.unwrap_or(ResultTools.map(ResultTools.flat_map(PositiveInt_Impl_.parse(10), fn n -> PositiveInt_Impl_.safe_sub(n, ResultTools.unwrap(PositiveInt_Impl_.parse(3))) end), fn n -> PositiveInt_Impl_.multiply(n, ResultTools.unwrap(PositiveInt_Impl_.parse(2))) end), ResultTools.unwrap(PositiveInt_Impl_.parse(1)))
    _ = Log.trace("Math chain result: #{(fn -> PositiveInt_Impl_.to_string(math_chain) end).()}", %{:file_name => "Main.hx", :line_number => 351, :class_name => "Main", :method_name => "testFunctionalComposition"})
    _ = MyApp.ResultTools.unwrap_or(ResultTools.flat_map(ResultTools.map(ResultTools.flat_map(NonEmptyString_Impl_.parse_and_trim("  hello world  "), fn s -> NonEmptyString_Impl_.safe_trim(s) end), fn s -> NonEmptyString_Impl_.to_upper_case(s) end), fn s -> NonEmptyString_Impl_.safe_replace(s, "WORLD", "UNIVERSE") end), ResultTools.unwrap(NonEmptyString_Impl_.parse("fallback")))
    _ = Log.trace("String chain result: #{(fn -> NonEmptyString_Impl_.to_string(string_chain) end).()}", %{:file_name => "Main.hx", :line_number => 359, :class_name => "Main", :method_name => "testFunctionalComposition"})
    parsed_result = build_user_profile("user123", "  alice@example.com  ", "5")
    (case parsed_result do
      {:ok, _} ->
        to_string = _
        user_id = _
        _ = Log.trace("User profile created successfully:", %{:file_name => "Main.hx", :line_number => 365, :class_name => "Main", :method_name => "testFunctionalComposition"})
        _ = Log.trace("  UserId: #{(fn -> UserId_Impl_.to_string(profile.user_id) end).()}", %{:file_name => "Main.hx", :line_number => 366, :class_name => "Main", :method_name => "testFunctionalComposition"})
        _ = Log.trace("  Email: #{(fn -> Email_Impl_.to_string(profile.email) end).()}", %{:file_name => "Main.hx", :line_number => 367, :class_name => "Main", :method_name => "testFunctionalComposition"})
        _ = Log.trace("  Score: #{(fn -> PositiveInt_Impl_.to_string(profile.score) end).()}", %{:file_name => "Main.hx", :line_number => 368, :class_name => "Main", :method_name => "testFunctionalComposition"})
      {:error, reason} ->
        Log.trace("User profile creation failed: #{(fn -> reason end).()}", %{:file_name => "Main.hx", :line_number => 370, :class_name => "Main", :method_name => "testFunctionalComposition"})
    end)
  end
  defp test_error_handling() do
    _ = Log.trace("=== Error Handling Tests ===", %{:file_name => "Main.hx", :line_number => 378, :class_name => "Main", :method_name => "testErrorHandling"})
    _ = [%{:email => "invalid-email", :user_id => "ab", :score => "0"}, %{:email => "user@domain", :user_id => "user@123", :score => "-5"}, %{:email => "", :user_id => "", :score => "not-a-number"}]
    _ = Enum.each(invalid_inputs, (fn -> fn item ->
    (case build_user_profile(item.user_id, item.email, item.score) do
    {:ok, value} ->
      Log.trace("ERROR: Invalid input was accepted", %{:file_name => "Main.hx", :line_number => 390, :class_name => "Main", :method_name => "testErrorHandling"})
    {:error, reason} ->
      Log.trace("Correctly rejected invalid input: " <> reason, %{:file_name => "Main.hx", :line_number => 392, :class_name => "Main", :method_name => "testErrorHandling"})
  end)
end end).())
    _ = Log.trace("Testing edge cases that should succeed:", %{:file_name => "Main.hx", :line_number => 397, :class_name => "Main", :method_name => "testErrorHandling"})
    _ = [%{:email => "a@b.co", :user_id => "usr", :score => "1"}, %{:email => "very.long.email.address@very.long.domain.name.example.com", :user_id => "user123456789", :score => "999"}]
    _ = Enum.each(edge_cases, (fn -> fn item ->
    (case build_user_profile(item.user_id, item.email, item.score) do
    {:ok, value} ->
      Log.trace("Edge case succeeded: UserId " <> UserId_Impl_.to_string(profile.user_id) <> ", Email " <> Email_Impl_.get_domain(profile.email), %{:file_name => "Main.hx", :line_number => 407, :class_name => "Main", :method_name => "testErrorHandling"})
    {:error, reason} ->
      Log.trace("Edge case failed: " <> reason, %{:file_name => "Main.hx", :line_number => 409, :class_name => "Main", :method_name => "testErrorHandling"})
  end)
end end).())
    _
  end
  defp test_real_world_scenarios() do
    _ = Log.trace("=== Real-World Scenarios ===", %{:file_name => "Main.hx", :line_number => 418, :class_name => "Main", :method_name => "testRealWorldScenarios"})
    _ = [%{:user_id => "alice123", :email => "alice@example.com", :preferred_name => "Alice Smith"}, %{:user_id => "bob456", :email => "bob.jones@company.org", :preferred_name => "Bob"}, %{:user_id => "charlie", :email => "charlie@test.dev", :preferred_name => "Charlie Brown"}]
    _ = []
    _ = Enum.each(registration_data, (fn -> fn item ->
    user_result = create_user(user_data.user_id, user_data.email, user_data.preferred_name)
  (case item do
    {:ok, value} ->
      item = Enum.concat(item, [item])
      Log.trace("User created: " <> NonEmptyString_Impl_.to_string(user.display_name) <> " (" <> Email_Impl_.to_string(user.email) <> ")", %{:file_name => "Main.hx", :line_number => 434, :class_name => "Main", :method_name => "testRealWorldScenarios"})
    {:error, reason} ->
      Log.trace("User creation failed: " <> reason, %{:file_name => "Main.hx", :line_number => 436, :class_name => "Main", :method_name => "testRealWorldScenarios"})
  end)
end end).())
    _ = Log.trace("Successfully created #{(fn -> length(valid_users) end).()} users", %{:file_name => "Main.hx", :line_number => 440, :class_name => "Main", :method_name => "testRealWorldScenarios"})
    _ = [%{:timeout => "30", :retries => "3", :name => "production"}, %{:timeout => "0", :retries => "5", :name => ""}, %{:timeout => "60", :retries => "-1", :name => "test"}]
    _ = Enum.each(config_data, (fn -> fn item ->
    config_result = validate_configuration(config.timeout, config.retries, config.name)
  (case item do
    {:ok, value} ->
      Log.trace("Config valid: " <> NonEmptyString_Impl_.to_string(validConfig.name) <> ", timeout: " <> PositiveInt_Impl_.to_string(validConfig.timeout) <> "s, retries: " <> PositiveInt_Impl_.to_string(validConfig.retries), %{:file_name => "Main.hx", :line_number => 453, :class_name => "Main", :method_name => "testRealWorldScenarios"})
    {:error, reason} ->
      Log.trace("Config invalid: " <> reason, %{:file_name => "Main.hx", :line_number => 455, :class_name => "Main", :method_name => "testRealWorldScenarios"})
  end)
end end).())
    _
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
    _ = String.to_integer(timeout_str)
    _ = String.to_integer(retries_str)
    if (Kernel.is_nil(timeout_int)), do: {:error, "Timeout must be a number: " <> timeout_str}
    if (Kernel.is_nil(retries_int)), do: {:error, "Retries must be a number: " <> retries_str}
    _ = MyApp.ResultTools.flat_map(ResultTools.map_error(PositiveInt_Impl_.parse(timeout_int), fn e -> "Invalid timeout: " <> e end), fn timeout -> ResultTools.flat_map(ResultTools.map_error(PositiveInt_Impl_.parse(retries_int), fn e -> "Invalid retries: " <> e end), fn retries -> ResultTools.map(ResultTools.map_error(NonEmptyString_Impl_.parse_and_trim(name_str), fn e -> "Invalid name: " <> e end), fn name -> %{:timeout => timeout, :retries => retries, :name => name} end) end) end)
    _
  end
end
