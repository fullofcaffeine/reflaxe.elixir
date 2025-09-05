defmodule Main do
  defp main() do
    Log.trace("Testing domain abstractions with type safety...", %{:fileName => "Main.hx", :lineNumber => 27, :className => "Main", :methodName => "main"})
    test_email_validation()
    test_user_id_validation()
    test_positive_int_arithmetic()
    test_non_empty_string_operations()
    test_functional_composition()
    test_error_handling()
    test_real_world_scenarios()
    Log.trace("Domain abstraction tests completed!", %{:fileName => "Main.hx", :lineNumber => 37, :className => "Main", :methodName => "main"})
  end
  defp test_email_validation() do
    Log.trace("=== Email Validation Tests ===", %{:fileName => "Main.hx", :lineNumber => 44, :className => "Main", :methodName => "testEmailValidation"})
    email_result = {:Parse, "user@example.com"}
    case (elem(email_result, 0)) do
      0 ->
        g = elem(email_result, 1)
        email = g
        domain = Email_Impl_.get_domain(email)
        local_part = Email_Impl_.get_local_part(email)
        Log.trace("Valid email - Domain: " <> domain <> ", Local: " <> local_part, %{:fileName => "Main.hx", :lineNumber => 52, :className => "Main", :methodName => "testEmailValidation"})
        is_example_domain = Email_Impl_.has_domain(email, "example.com")
        Log.trace("Is example.com domain: " <> Std.string(is_example_domain), %{:fileName => "Main.hx", :lineNumber => 56, :className => "Main", :methodName => "testEmailValidation"})
        normalized = Email_Impl_.normalize(email)
        Log.trace("Normalized: " <> Email_Impl_.to_string(normalized), %{:fileName => "Main.hx", :lineNumber => 60, :className => "Main", :methodName => "testEmailValidation"})
      1 ->
        g = elem(email_result, 1)
        reason = g
        Log.trace("Unexpected email validation failure: " <> reason, %{:fileName => "Main.hx", :lineNumber => 63, :className => "Main", :methodName => "testEmailValidation"})
    end
    invalid_emails = ["invalid-email", "@example.com", "user@", "user@@example.com", "", "user space@example.com"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {invalid_emails, g, :ok}, fn _, {acc_invalid_emails, acc_g, acc_state} ->
  if (acc_g < acc_invalid_emails.length) do
    invalid_email = invalid_emails[g]
    acc_g = acc_g + 1
    acc_g = {:Parse, invalid_email}
    case (elem(acc_g, 0)) do
      0 ->
        _g = elem(acc_g, 1)
        Log.trace("ERROR: Invalid email \"" <> invalid_email <> "\" was accepted", %{:fileName => "Main.hx", :lineNumber => 79, :className => "Main", :methodName => "testEmailValidation"})
      1 ->
        acc_g = elem(acc_g, 1)
        reason = acc_g
        Log.trace("Correctly rejected \"" <> invalid_email <> "\": " <> reason, %{:fileName => "Main.hx", :lineNumber => 81, :className => "Main", :methodName => "testEmailValidation"})
    end
    {:cont, {acc_invalid_emails, acc_g, acc_state}}
  else
    {:halt, {acc_invalid_emails, acc_g, acc_state}}
  end
end)
    email1_result = {:Parse, "Test@Example.Com"}
    email2_result = {:Parse, "test@example.com"}
    if (ResultTools.is_ok(email1_result) && ResultTools.is_ok(email2_result)) do
      email1 = ResultTools.unwrap(email1_result)
      email2 = ResultTools.unwrap(email2_result)
      are_equal = Email_Impl_.equals(email1, email2)
      Log.trace("Case-insensitive equality: " <> Std.string(are_equal), %{:fileName => "Main.hx", :lineNumber => 93, :className => "Main", :methodName => "testEmailValidation"})
    end
  end
  defp test_user_id_validation() do
    Log.trace("=== UserId Validation Tests ===", %{:fileName => "Main.hx", :lineNumber => 101, :className => "Main", :methodName => "testUserIdValidation"})
    valid_ids = ["user123", "Alice", "Bob42", "testUser"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {valid_ids, g, :ok}, fn _, {acc_valid_ids, acc_g, acc_state} ->
  if (acc_g < acc_valid_ids.length) do
    valid_id = valid_ids[g]
    acc_g = acc_g + 1
    acc_g = {:Parse, valid_id}
    case (elem(acc_g, 0)) do
      0 ->
        acc_g = elem(acc_g, 1)
        user_id = acc_g
        length = UserId_Impl_.length(user_id)
        normalized = UserId_Impl_.normalize(user_id)
        Log.trace("Valid UserId \"" <> valid_id <> "\" - Length: " <> length <> ", Normalized: " <> UserId_Impl_.to_string(normalized), %{:fileName => "Main.hx", :lineNumber => 111, :className => "Main", :methodName => "testUserIdValidation"})
        starts_with_user = UserId_Impl_.starts_with_ignore_case(user_id, "user")
        Log.trace("Starts with \"user\" (case-insensitive): " <> Std.string(starts_with_user), %{:fileName => "Main.hx", :lineNumber => 115, :className => "Main", :methodName => "testUserIdValidation"})
      1 ->
        acc_g = elem(acc_g, 1)
        reason = acc_g
        Log.trace("Unexpected UserId validation failure for \"" <> valid_id <> "\": " <> reason, %{:fileName => "Main.hx", :lineNumber => 118, :className => "Main", :methodName => "testUserIdValidation"})
    end
    {:cont, {acc_valid_ids, acc_g, acc_state}}
  else
    {:halt, {acc_valid_ids, acc_g, acc_state}}
  end
end)
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {invalid_ids, g, :ok}, fn _, {acc_invalid_ids, acc_g, acc_state} ->
  if (acc_g < acc_invalid_ids.length) do
    invalid_id = invalid_ids[g]
    acc_g = acc_g + 1
    acc_g = {:Parse, invalid_id}
    case (elem(acc_g, 0)) do
      0 ->
        _g = elem(acc_g, 1)
        Log.trace("ERROR: Invalid UserId \"" <> invalid_id <> "\" was accepted", %{:fileName => "Main.hx", :lineNumber => 135, :className => "Main", :methodName => "testUserIdValidation"})
      1 ->
        acc_g = elem(acc_g, 1)
        reason = acc_g
        Log.trace("Correctly rejected \"" <> invalid_id <> "\": " <> reason, %{:fileName => "Main.hx", :lineNumber => 137, :className => "Main", :methodName => "testUserIdValidation"})
    end
    {:cont, {acc_invalid_ids, acc_g, acc_state}}
  else
    {:halt, {acc_invalid_ids, acc_g, acc_state}}
  end
end)
    id1_result = {:Parse, "User123"}
    id2_result = {:Parse, "user123"}
    if (ResultTools.is_ok(id1_result) && ResultTools.is_ok(id2_result)) do
      id1 = ResultTools.unwrap(id1_result)
      id2 = ResultTools.unwrap(id2_result)
      exact_equal = UserId_Impl_.equals(id1, id2)
      case_insensitive_equal = UserId_Impl_.equals_ignore_case(id1, id2)
      Log.trace("Exact equality: " <> Std.string(exact_equal) <> ", Case-insensitive: " <> Std.string(case_insensitive_equal), %{:fileName => "Main.hx", :lineNumber => 150, :className => "Main", :methodName => "testUserIdValidation"})
    end
  end
  defp test_positive_int_arithmetic() do
    Log.trace("=== PositiveInt Arithmetic Tests ===", %{:fileName => "Main.hx", :lineNumber => 158, :className => "Main", :methodName => "testPositiveIntArithmetic"})
    valid_numbers = [1, 5, 42, 100, 999]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, valid_numbers, :ok}, fn _, {acc_g, acc_valid_numbers, acc_state} ->
  if (acc_g < acc_valid_numbers.length) do
    valid_num = valid_numbers[g]
    acc_g = acc_g + 1
    acc_g = {:Parse, valid_num}
    case (elem(acc_g, 0)) do
      0 ->
        acc_g = elem(acc_g, 1)
        pos_int = acc_g
        Log.trace("Valid PositiveInt: " <> PositiveInt_Impl_.to_string(pos_int), %{:fileName => "Main.hx", :lineNumber => 166, :className => "Main", :methodName => "testPositiveIntArithmetic"})
        doubled = PositiveInt_Impl_.multiply(pos_int, ResultTools.unwrap({:Parse, 2}))
        added = PositiveInt_Impl_.add(pos_int, ResultTools.unwrap({:Parse, 10}))
        Log.trace("Doubled: " <> PositiveInt_Impl_.to_string(doubled) <> ", Added 10: " <> PositiveInt_Impl_.to_string(added), %{:fileName => "Main.hx", :lineNumber => 171, :className => "Main", :methodName => "testPositiveIntArithmetic"})
        subtract_result = {:SafeSub, pos_int, ResultTools.unwrap({:Parse, 1})}
        case (elem(subtract_result, 0)) do
          0 ->
            acc_g = elem(subtract_result, 1)
            result = acc_g
            Log.trace("Safe subtraction result: " <> PositiveInt_Impl_.to_string(result), %{:fileName => "Main.hx", :lineNumber => 177, :className => "Main", :methodName => "testPositiveIntArithmetic"})
          1 ->
            acc_g = elem(subtract_result, 1)
            reason = acc_g
            Log.trace("Safe subtraction failed: " <> reason, %{:fileName => "Main.hx", :lineNumber => 179, :className => "Main", :methodName => "testPositiveIntArithmetic"})
        end
        five = ResultTools.unwrap({:Parse, 5})
        is_greater = PositiveInt_Impl_.greater_than(pos_int, five)
        min = PositiveInt_Impl_.min(pos_int, five)
        max = PositiveInt_Impl_.max(pos_int, five)
        Log.trace("Greater than 5: " <> Std.string(is_greater) <> ", Min with 5: " <> PositiveInt_Impl_.to_string(min) <> ", Max with 5: " <> PositiveInt_Impl_.to_string(max), %{:fileName => "Main.hx", :lineNumber => 187, :className => "Main", :methodName => "testPositiveIntArithmetic"})
      1 ->
        acc_g = elem(acc_g, 1)
        reason = acc_g
        Log.trace("Unexpected PositiveInt validation failure for " <> valid_num <> ": " <> reason, %{:fileName => "Main.hx", :lineNumber => 190, :className => "Main", :methodName => "testPositiveIntArithmetic"})
    end
    {:cont, {acc_g, acc_valid_numbers, acc_state}}
  else
    {:halt, {acc_g, acc_valid_numbers, acc_state}}
  end
end)
    invalid_numbers = [0, -1, -42, -100]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, invalid_numbers, :ok}, fn _, {acc_g, acc_invalid_numbers, acc_state} ->
  if (acc_g < acc_invalid_numbers.length) do
    invalid_num = invalid_numbers[g]
    acc_g = acc_g + 1
    acc_g = {:Parse, invalid_num}
    case (elem(acc_g, 0)) do
      0 ->
        _g = elem(acc_g, 1)
        Log.trace("ERROR: Invalid PositiveInt " <> invalid_num <> " was accepted", %{:fileName => "Main.hx", :lineNumber => 200, :className => "Main", :methodName => "testPositiveIntArithmetic"})
      1 ->
        acc_g = elem(acc_g, 1)
        reason = acc_g
        Log.trace("Correctly rejected " <> invalid_num <> ": " <> reason, %{:fileName => "Main.hx", :lineNumber => 202, :className => "Main", :methodName => "testPositiveIntArithmetic"})
    end
    {:cont, {acc_g, acc_invalid_numbers, acc_state}}
  else
    {:halt, {acc_g, acc_invalid_numbers, acc_state}}
  end
end)
    five = ResultTools.unwrap({:Parse, 5})
    ten = ResultTools.unwrap({:Parse, 10})
    g = {:SafeSub, five, ten}
    case (elem(g, 0)) do
      0 ->
        _g = elem(g, 1)
        Log.trace("ERROR: Subtraction that should fail succeeded", %{:fileName => "Main.hx", :lineNumber => 213, :className => "Main", :methodName => "testPositiveIntArithmetic"})
      1 ->
        g = elem(g, 1)
        reason = g
        Log.trace("Correctly prevented invalid subtraction: " <> reason, %{:fileName => "Main.hx", :lineNumber => 215, :className => "Main", :methodName => "testPositiveIntArithmetic"})
    end
    twenty = ResultTools.unwrap({:Parse, 20})
    four = ResultTools.unwrap({:Parse, 4})
    three = ResultTools.unwrap({:Parse, 3})
    g = {:SafeDiv, twenty, four}
    case (elem(g, 0)) do
      0 ->
        g = elem(g, 1)
        result = g
        Log.trace("20 / 4 = " <> PositiveInt_Impl_.to_string(result), %{:fileName => "Main.hx", :lineNumber => 225, :className => "Main", :methodName => "testPositiveIntArithmetic"})
      1 ->
        g = elem(g, 1)
        reason = g
        Log.trace("Division failed: " <> reason, %{:fileName => "Main.hx", :lineNumber => 227, :className => "Main", :methodName => "testPositiveIntArithmetic"})
    end
    g = {:SafeDiv, twenty, three}
    case (elem(g, 0)) do
      0 ->
        g = elem(g, 1)
        result = g
        Log.trace("20 / 3 = " <> PositiveInt_Impl_.to_string(result) <> " (unexpected success)", %{:fileName => "Main.hx", :lineNumber => 232, :className => "Main", :methodName => "testPositiveIntArithmetic"})
      1 ->
        g = elem(g, 1)
        reason = g
        Log.trace("20 / 3 correctly failed (not exact): " <> reason, %{:fileName => "Main.hx", :lineNumber => 234, :className => "Main", :methodName => "testPositiveIntArithmetic"})
    end
  end
  defp test_non_empty_string_operations() do
    Log.trace("=== NonEmptyString Operations Tests ===", %{:fileName => "Main.hx", :lineNumber => 242, :className => "Main", :methodName => "testNonEmptyStringOperations"})
    valid_strings = ["hello", "world", "test", "NonEmptyString"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {valid_strings, g, :ok}, fn _, {acc_valid_strings, acc_g, acc_state} ->
  if (acc_g < acc_valid_strings.length) do
    valid_str = valid_strings[g]
    acc_g = acc_g + 1
    acc_g = {:Parse, valid_str}
    case (elem(acc_g, 0)) do
      0 ->
        acc_g = elem(acc_g, 1)
        non_empty_str = acc_g
        length = NonEmptyString_Impl_.length(non_empty_str)
        upper = NonEmptyString_Impl_.to_upper_case(non_empty_str)
        lower = NonEmptyString_Impl_.to_lower_case(non_empty_str)
        Log.trace("Valid NonEmptyString \"" <> valid_str <> "\" - Length: " <> length <> ", Upper: " <> NonEmptyString_Impl_.to_string(upper) <> ", Lower: " <> NonEmptyString_Impl_.to_string(lower), %{:fileName => "Main.hx", :lineNumber => 253, :className => "Main", :methodName => "testNonEmptyStringOperations"})
        other = ResultTools.unwrap({:Parse, "!"})
        concatenated = NonEmptyString_Impl_.concat(non_empty_str, other)
        Log.trace("Concatenated with \"!\": " <> NonEmptyString_Impl_.to_string(concatenated), %{:fileName => "Main.hx", :lineNumber => 258, :className => "Main", :methodName => "testNonEmptyStringOperations"})
        first_char = NonEmptyString_Impl_.first_char(non_empty_str)
        last_char = NonEmptyString_Impl_.last_char(non_empty_str)
        Log.trace("First char: " <> NonEmptyString_Impl_.to_string(first_char) <> ", Last char: " <> NonEmptyString_Impl_.to_string(last_char), %{:fileName => "Main.hx", :lineNumber => 263, :className => "Main", :methodName => "testNonEmptyStringOperations"})
        acc_g = {:SafeSubstring, non_empty_str, 1}
        case (elem(acc_g, 0)) do
          0 ->
            acc_g = elem(acc_g, 1)
            substr = acc_g
            Log.trace("Substring from index 1: " <> NonEmptyString_Impl_.to_string(substr), %{:fileName => "Main.hx", :lineNumber => 268, :className => "Main", :methodName => "testNonEmptyStringOperations"})
          1 ->
            acc_g = elem(acc_g, 1)
            reason = acc_g
            Log.trace("Substring failed: " <> reason, %{:fileName => "Main.hx", :lineNumber => 270, :className => "Main", :methodName => "testNonEmptyStringOperations"})
        end
      1 ->
        acc_g = elem(acc_g, 1)
        reason = acc_g
        Log.trace("Unexpected NonEmptyString validation failure for \"" <> valid_str <> "\": " <> reason, %{:fileName => "Main.hx", :lineNumber => 274, :className => "Main", :methodName => "testNonEmptyStringOperations"})
    end
    {:cont, {acc_valid_strings, acc_g, acc_state}}
  else
    {:halt, {acc_valid_strings, acc_g, acc_state}}
  end
end)
    invalid_strings = ["", "   ", "\t\n"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {invalid_strings, g, :ok}, fn _, {acc_invalid_strings, acc_g, acc_state} ->
  if (acc_g < acc_invalid_strings.length) do
    invalid_str = invalid_strings[g]
    acc_g = acc_g + 1
    acc_g = {:Parse, invalid_str}
    case (elem(acc_g, 0)) do
      0 ->
        _g = elem(acc_g, 1)
        Log.trace("ERROR: Invalid NonEmptyString \"" <> invalid_str <> "\" was accepted", %{:fileName => "Main.hx", :lineNumber => 284, :className => "Main", :methodName => "testNonEmptyStringOperations"})
      1 ->
        acc_g = elem(acc_g, 1)
        reason = acc_g
        Log.trace("Correctly rejected \"" <> invalid_str <> "\": " <> reason, %{:fileName => "Main.hx", :lineNumber => 286, :className => "Main", :methodName => "testNonEmptyStringOperations"})
    end
    {:cont, {acc_invalid_strings, acc_g, acc_state}}
  else
    {:halt, {acc_invalid_strings, acc_g, acc_state}}
  end
end)
    whitespace_strings = ["  hello  ", "\tworld\n", "  test  "]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {whitespace_strings, g, :ok}, fn _, {acc_whitespace_strings, acc_g, acc_state} ->
  if (acc_g < acc_whitespace_strings.length) do
    whitespace_str = whitespace_strings[g]
    acc_g = acc_g + 1
    acc_g = {:ParseAndTrim, whitespace_str}
    case (elem(acc_g, 0)) do
      0 ->
        acc_g = elem(acc_g, 1)
        trimmed = acc_g
        Log.trace("Trimmed \"" <> whitespace_str <> "\" to \"" <> NonEmptyString_Impl_.to_string(trimmed) <> "\"", %{:fileName => "Main.hx", :lineNumber => 296, :className => "Main", :methodName => "testNonEmptyStringOperations"})
      1 ->
        acc_g = elem(acc_g, 1)
        reason = acc_g
        Log.trace("Trim and parse failed for \"" <> whitespace_str <> "\": " <> reason, %{:fileName => "Main.hx", :lineNumber => 298, :className => "Main", :methodName => "testNonEmptyStringOperations"})
    end
    {:cont, {acc_whitespace_strings, acc_g, acc_state}}
  else
    {:halt, {acc_whitespace_strings, acc_g, acc_state}}
  end
end)
    test_str = ResultTools.unwrap({:Parse, "Hello World"})
    starts_with_hello = NonEmptyString_Impl_.starts_with(test_str, "Hello")
    ends_with_world = NonEmptyString_Impl_.ends_with(test_str, "World")
    contains_space = NonEmptyString_Impl_.contains(test_str, " ")
    Log.trace("String operations - Starts with \"Hello\": " <> Std.string(starts_with_hello) <> ", Ends with \"World\": " <> Std.string(ends_with_world) <> ", Contains space: " <> Std.string(contains_space), %{:fileName => "Main.hx", :lineNumber => 307, :className => "Main", :methodName => "testNonEmptyStringOperations"})
    g = {:SafeReplace, test_str, "World", "Universe"}
    case (elem(g, 0)) do
      0 ->
        g = elem(g, 1)
        replaced = g
        Log.trace("Replaced \"World\" with \"Universe\": " <> NonEmptyString_Impl_.to_string(replaced), %{:fileName => "Main.hx", :lineNumber => 312, :className => "Main", :methodName => "testNonEmptyStringOperations"})
      1 ->
        g = elem(g, 1)
        reason = g
        Log.trace("Replacement failed: " <> reason, %{:fileName => "Main.hx", :lineNumber => 314, :className => "Main", :methodName => "testNonEmptyStringOperations"})
    end
    parts = NonEmptyString_Impl_.split_non_empty(test_str, " ")
    Log.trace("Split by space: " <> parts.length <> " parts", %{:fileName => "Main.hx", :lineNumber => 319, :className => "Main", :methodName => "testNonEmptyStringOperations"})
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, parts, :ok}, fn _, {acc_g, acc_parts, acc_state} ->
  if (acc_g < acc_parts.length) do
    part = parts[g]
    acc_g = acc_g + 1
    Log.trace("  Part: " <> NonEmptyString_Impl_.to_string(part), %{:fileName => "Main.hx", :lineNumber => 321, :className => "Main", :methodName => "testNonEmptyStringOperations"})
    {:cont, {acc_g, acc_parts, acc_state}}
  else
    {:halt, {acc_g, acc_parts, acc_state}}
  end
end)
  end
  defp test_functional_composition() do
    Log.trace("=== Functional Composition Tests ===", %{:fileName => "Main.hx", :lineNumber => 329, :className => "Main", :methodName => "testFunctionalComposition"})
    email_chain = ResultTools.unwrap_or({:Map, {:Map, {:Parse, "USER@EXAMPLE.COM"}, fn email -> Email_Impl_.normalize(email) end}, fn email -> Email_Impl_.get_domain(email) end}, "unknown")
    Log.trace("Email chain result: " <> email_chain, %{:fileName => "Main.hx", :lineNumber => 336, :className => "Main", :methodName => "testFunctionalComposition"})
    user_id_chain = ResultTools.unwrap_or({:Filter, {:Map, {:Parse, "TestUser123"}, fn user_id -> UserId_Impl_.normalize(user_id) end}, fn user_id -> UserId_Impl_.starts_with(user_id, "test") end, "UserId does not start with 'test'"}, ResultTools.unwrap({:Parse, "defaultuser"}))
    Log.trace("UserId chain result: " <> UserId_Impl_.to_string(user_id_chain), %{:fileName => "Main.hx", :lineNumber => 343, :className => "Main", :methodName => "testFunctionalComposition"})
    math_chain = ResultTools.unwrap_or({:Map, {:FlatMap, {:Parse, 10}, fn n -> {:SafeSub, n, ResultTools.unwrap({:Parse, 3})} end}, fn n -> PositiveInt_Impl_.multiply(n, ResultTools.unwrap({:Parse, 2})) end}, ResultTools.unwrap({:Parse, 1}))
    Log.trace("Math chain result: " <> PositiveInt_Impl_.to_string(math_chain), %{:fileName => "Main.hx", :lineNumber => 350, :className => "Main", :methodName => "testFunctionalComposition"})
    string_chain = ResultTools.unwrap_or({:FlatMap, {:Map, {:FlatMap, {:ParseAndTrim, "  hello world  "}, fn s -> {:SafeTrim, s} end}, fn s -> NonEmptyString_Impl_.to_upper_case(s) end}, fn s -> {:SafeReplace, s, "WORLD", "UNIVERSE"} end}, ResultTools.unwrap({:Parse, "fallback"}))
    Log.trace("String chain result: " <> NonEmptyString_Impl_.to_string(string_chain), %{:fileName => "Main.hx", :lineNumber => 358, :className => "Main", :methodName => "testFunctionalComposition"})
    composition_result = {:BuildUserProfile, "user123", "  alice@example.com  ", "5"}
    case (elem(composition_result, 0)) do
      0 ->
        g = elem(composition_result, 1)
        profile = g
        Log.trace("User profile created successfully:", %{:fileName => "Main.hx", :lineNumber => 364, :className => "Main", :methodName => "testFunctionalComposition"})
        Log.trace("  UserId: " <> UserId_Impl_.to_string(profile.userId), %{:fileName => "Main.hx", :lineNumber => 365, :className => "Main", :methodName => "testFunctionalComposition"})
        Log.trace("  Email: " <> Email_Impl_.to_string(profile.email), %{:fileName => "Main.hx", :lineNumber => 366, :className => "Main", :methodName => "testFunctionalComposition"})
        Log.trace("  Score: " <> PositiveInt_Impl_.to_string(profile.score), %{:fileName => "Main.hx", :lineNumber => 367, :className => "Main", :methodName => "testFunctionalComposition"})
      1 ->
        g = elem(composition_result, 1)
        reason = g
        Log.trace("User profile creation failed: " <> reason, %{:fileName => "Main.hx", :lineNumber => 369, :className => "Main", :methodName => "testFunctionalComposition"})
    end
  end
  defp test_error_handling() do
    Log.trace("=== Error Handling Tests ===", %{:fileName => "Main.hx", :lineNumber => 377, :className => "Main", :methodName => "testErrorHandling"})
    invalid_inputs = [%{:email => "invalid-email", :userId => "ab", :score => "0"}, %{:email => "user@domain", :userId => "user@123", :score => "-5"}, %{:email => "", :userId => "", :score => "not-a-number"}]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, invalid_inputs, :ok}, fn _, {acc_g, acc_invalid_inputs, acc_state} ->
  if (acc_g < acc_invalid_inputs.length) do
    input = invalid_inputs[g]
    acc_g = acc_g + 1
    acc_g = {:BuildUserProfile, input[:userId], input[:email], input[:score]}
    case (elem(acc_g, 0)) do
      0 ->
        _g = elem(acc_g, 1)
        Log.trace("ERROR: Invalid input was accepted", %{:fileName => "Main.hx", :lineNumber => 389, :className => "Main", :methodName => "testErrorHandling"})
      1 ->
        acc_g = elem(acc_g, 1)
        reason = acc_g
        Log.trace("Correctly rejected invalid input: " <> reason, %{:fileName => "Main.hx", :lineNumber => 391, :className => "Main", :methodName => "testErrorHandling"})
    end
    {:cont, {acc_g, acc_invalid_inputs, acc_state}}
  else
    {:halt, {acc_g, acc_invalid_inputs, acc_state}}
  end
end)
    Log.trace("Testing edge cases that should succeed:", %{:fileName => "Main.hx", :lineNumber => 396, :className => "Main", :methodName => "testErrorHandling"})
    edge_cases = [%{:email => "a@b.co", :userId => "usr", :score => "1"}, %{:email => "very.long.email.address@very.long.domain.name.example.com", :userId => "user123456789", :score => "999"}]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, edge_cases, :ok}, fn _, {acc_g, acc_edge_cases, acc_state} ->
  if (acc_g < acc_edge_cases.length) do
    edge_case = edge_cases[g]
    acc_g = acc_g + 1
    acc_g = {:BuildUserProfile, edge_case[:userId], edge_case[:email], edge_case[:score]}
    case (elem(acc_g, 0)) do
      0 ->
        acc_g = elem(acc_g, 1)
        profile = acc_g
        Log.trace("Edge case succeeded: UserId " <> UserId_Impl_.to_string(profile.userId) <> ", Email " <> Email_Impl_.get_domain(profile.email), %{:fileName => "Main.hx", :lineNumber => 406, :className => "Main", :methodName => "testErrorHandling"})
      1 ->
        acc_g = elem(acc_g, 1)
        reason = acc_g
        Log.trace("Edge case failed: " <> reason, %{:fileName => "Main.hx", :lineNumber => 408, :className => "Main", :methodName => "testErrorHandling"})
    end
    {:cont, {acc_g, acc_edge_cases, acc_state}}
  else
    {:halt, {acc_g, acc_edge_cases, acc_state}}
  end
end)
  end
  defp test_real_world_scenarios() do
    Log.trace("=== Real-World Scenarios ===", %{:fileName => "Main.hx", :lineNumber => 417, :className => "Main", :methodName => "testRealWorldScenarios"})
    registration_data = [%{:userId => "alice123", :email => "alice@example.com", :preferredName => "Alice Smith"}, %{:userId => "bob456", :email => "bob.jones@company.org", :preferredName => "Bob"}, %{:userId => "charlie", :email => "charlie@test.dev", :preferredName => "Charlie Brown"}]
    valid_users = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, registration_data, :ok}, fn _, {acc_g, acc_registration_data, acc_state} ->
  if (acc_g < acc_registration_data.length) do
    user_data = registration_data[g]
    acc_g = acc_g + 1
    user_result = {:CreateUser, user_data[:userId], user_data[:email], user_data[:preferredName]}
    case (elem(user_result, 0)) do
      0 ->
        acc_g = elem(user_result, 1)
        user = acc_g
        valid_users ++ [user]
        Log.trace("User created: " <> NonEmptyString_Impl_.to_string(user.displayName) <> " (" <> Email_Impl_.to_string(user.email) <> ")", %{:fileName => "Main.hx", :lineNumber => 433, :className => "Main", :methodName => "testRealWorldScenarios"})
      1 ->
        acc_g = elem(user_result, 1)
        reason = acc_g
        Log.trace("User creation failed: " <> reason, %{:fileName => "Main.hx", :lineNumber => 435, :className => "Main", :methodName => "testRealWorldScenarios"})
    end
    {:cont, {acc_g, acc_registration_data, acc_state}}
  else
    {:halt, {acc_g, acc_registration_data, acc_state}}
  end
end)
    Log.trace("Successfully created " <> valid_users.length <> " users", %{:fileName => "Main.hx", :lineNumber => 439, :className => "Main", :methodName => "testRealWorldScenarios"})
    config_data = [%{:timeout => "30", :retries => "3", :name => "production"}, %{:timeout => "0", :retries => "5", :name => ""}, %{:timeout => "60", :retries => "-1", :name => "test"}]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, config_data, :ok}, fn _, {acc_g, acc_config_data, acc_state} ->
  if (acc_g < acc_config_data.length) do
    config = config_data[g]
    acc_g = acc_g + 1
    config_result = {:ValidateConfiguration, config[:timeout], config[:retries], config[:name]}
    case (elem(config_result, 0)) do
      0 ->
        acc_g = elem(config_result, 1)
        valid_config = acc_g
        Log.trace("Config valid: " <> NonEmptyString_Impl_.to_string(valid_config.name) <> ", timeout: " <> PositiveInt_Impl_.to_string(valid_config.timeout) <> "s, retries: " <> PositiveInt_Impl_.to_string(valid_config.retries), %{:fileName => "Main.hx", :lineNumber => 452, :className => "Main", :methodName => "testRealWorldScenarios"})
      1 ->
        acc_g = elem(config_result, 1)
        reason = acc_g
        Log.trace("Config invalid: " <> reason, %{:fileName => "Main.hx", :lineNumber => 454, :className => "Main", :methodName => "testRealWorldScenarios"})
    end
    {:cont, {acc_g, acc_config_data, acc_state}}
  else
    {:halt, {acc_g, acc_config_data, acc_state}}
  end
end)
  end
  defp build_user_profile(user_id_str, email_str, score_str) do
    {:FlatMap, {:MapError, {:Parse, user_id_str}, fn e -> "Invalid UserId: " <> e end}, fn _user_id ->
  {:FlatMap, {:MapError, {:Parse, StringTools.ltrim(StringTools.rtrim(email_str))}, fn e -> "Invalid Email: " <> e end}, fn _email ->
  score_int = Std.parse_int(score_str)
  if (score_int == nil), do: {:Error, "Invalid score: " <> score_str}
  {:Map, {:MapError, {:Parse, score_int}, fn e -> "Invalid score: " <> e end}, fn score -> %{:userId => _user_id, :email => _email, :score => score} end}
end}
end}
  end
  defp create_user(user_id_str, email_str, name_str) do
    {:FlatMap, {:MapError, {:Parse, user_id_str}, fn e -> "Invalid UserId: " <> e end}, fn _user_id -> {:FlatMap, {:MapError, {:Parse, email_str}, fn e -> "Invalid Email: " <> e end}, fn _email -> {:Map, {:MapError, {:ParseAndTrim, name_str}, fn e -> "Invalid Name: " <> e end}, fn display_name -> %{:userId => _user_id, :email => _email, :displayName => display_name} end} end} end}
  end
  defp validate_configuration(timeout_str, retries_str, name_str) do
    timeout_int = Std.parse_int(timeout_str)
    retries_int = Std.parse_int(retries_str)
    if (timeout_int == nil), do: {:Error, "Timeout must be a number: " <> timeout_str}
    if (retries_int == nil), do: {:Error, "Retries must be a number: " <> retries_str}
    {:FlatMap, {:MapError, {:Parse, timeout_int}, fn e -> "Invalid timeout: " <> e end}, fn _timeout -> {:FlatMap, {:MapError, {:Parse, retries_int}, fn e -> "Invalid retries: " <> e end}, fn _retries -> {:Map, {:MapError, {:ParseAndTrim, name_str}, fn e -> "Invalid name: " <> e end}, fn name -> %{:timeout => _timeout, :retries => _retries, :name => name} end} end} end}
  end
end