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
    email_result = Email.parse("user@example.com")
    case email_result do
      {:ok, email} ->
        domain = Email.get_domain(email)
        local_part = Email.get_local_part(email)
        Log.trace("Valid email - Domain: #{domain}, Local: #{local_part}", %{:file_name => "Main.hx", :line_number => 52, :class_name => "Main", :method_name => "testEmailValidation"})
        is_example_domain = Email.has_domain(email, "example.com")
        Log.trace("Is example.com domain: #{is_example_domain}", %{:file_name => "Main.hx", :line_number => 56, :class_name => "Main", :method_name => "testEmailValidation"})
        normalized = Email.normalize(email)
        Log.trace("Normalized: #{Email.to_string(normalized)}", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "testEmailValidation"})
      {:error, reason} ->
        Log.trace("Unexpected email validation failure: #{reason}", %{:file_name => "Main.hx", :line_number => 63, :class_name => "Main", :method_name => "testEmailValidation"})
    end

    invalid_emails = ["invalid-email", "@example.com", "user@", "user@@example.com", "", "user space@example.com"]
    Enum.each(invalid_emails, fn invalid_email ->
      case Email.parse(invalid_email) do
        {:ok, _} ->
          Log.trace("ERROR: Invalid email parsed successfully: #{invalid_email}", %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "testEmailValidation"})
        {:error, _reason} ->
          :ok  # Expected failure
      end
    end)

    email1_result = Email.parse("Test@Example.Com")
    email2_result = Email.parse("test@example.com")
    if ResultTools.is_ok(email1_result) and ResultTools.is_ok(email2_result) do
      email1 = ResultTools.unwrap(email1_result)
      email2 = ResultTools.unwrap(email2_result)
      are_equal = Email.equals(email1, email2)
      Log.trace("Case-insensitive equality: #{are_equal}", %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "testEmailValidation"})
    end
  end

  defp test_user_id_validation() do
    Log.trace("=== UserId Validation Tests ===", %{:file_name => "Main.hx", :line_number => 101, :class_name => "Main", :method_name => "testUserIdValidation"})
    valid_ids = ["user123", "Alice", "Bob42", "testUser"]
    Enum.each(valid_ids, fn id_str ->
      case UserId.parse(id_str) do
        {:ok, user_id} ->
          Log.trace("Valid UserId: #{UserId.to_string(user_id)}", %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "testUserIdValidation"})
        {:error, reason} ->
          Log.trace("ERROR: Valid UserId rejected: #{id_str}, Reason: #{reason}", %{:file_name => "Main.hx", :line_number => 107, :class_name => "Main", :method_name => "testUserIdValidation"})
      end
    end)

    long_string = String.duplicate("a", 60)
    invalid_ids = ["ab", "user@123", "user 123", "user-123", "", long_string]
    Enum.each(invalid_ids, fn invalid_id ->
      case UserId.parse(invalid_id) do
        {:ok, _} ->
          Log.trace("ERROR: Invalid UserId parsed successfully: #{invalid_id}", %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "testUserIdValidation"})
        {:error, _reason} ->
          :ok  # Expected failure
      end
    end)

    id1_result = UserId.parse("User123")
    id2_result = UserId.parse("user123")
    if ResultTools.is_ok(id1_result) and ResultTools.is_ok(id2_result) do
      id1 = ResultTools.unwrap(id1_result)
      id2 = ResultTools.unwrap(id2_result)
      exact_equal = UserId.equals(id1, id2)
      case_insensitive_equal = UserId.equals_ignore_case(id1, id2)
      Log.trace("Exact equality: #{exact_equal}, Case-insensitive: #{case_insensitive_equal}", %{:file_name => "Main.hx", :line_number => 150, :class_name => "Main", :method_name => "testUserIdValidation"})
    end
  end

  defp test_positive_int_arithmetic() do
    Log.trace("=== PositiveInt Arithmetic Tests ===", %{:file_name => "Main.hx", :line_number => 158, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    valid_numbers = [1, 5, 42, 100, 999]
    Enum.each(valid_numbers, fn num ->
      case PositiveInt.parse(num) do
        {:ok, positive_int} ->
          Log.trace("Valid PositiveInt: #{PositiveInt.to_string(positive_int)}", %{:file_name => "Main.hx", :line_number => 163, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
        {:error, reason} ->
          Log.trace("ERROR: Valid number rejected: #{num}, Reason: #{reason}", %{:file_name => "Main.hx", :line_number => 165, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      end
    end)

    invalid_numbers = [0, -1, -42, -100]
    Enum.each(invalid_numbers, fn num ->
      case PositiveInt.parse(num) do
        {:ok, _} ->
          Log.trace("ERROR: Invalid number parsed successfully: #{num}", %{:file_name => "Main.hx", :line_number => 180, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
        {:error, _reason} ->
          :ok  # Expected failure
      end
    end)

    five = ResultTools.unwrap(PositiveInt.parse(5))
    ten = ResultTools.unwrap(PositiveInt.parse(10))
    case PositiveInt.safe_sub(five, ten) do
      {:ok, _} ->
        Log.trace("ERROR: Subtraction that should fail succeeded", %{:file_name => "Main.hx", :line_number => 213, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      {:error, reason} ->
        Log.trace("Correctly prevented invalid subtraction: #{reason}", %{:file_name => "Main.hx", :line_number => 215, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    end

    twenty = ResultTools.unwrap(PositiveInt.parse(20))
    four = ResultTools.unwrap(PositiveInt.parse(4))
    three = ResultTools.unwrap(PositiveInt.parse(3))

    case PositiveInt.safe_div(twenty, four) do
      {:ok, result} ->
        Log.trace("20 / 4 = #{PositiveInt.to_string(result)}", %{:file_name => "Main.hx", :line_number => 225, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      {:error, reason} ->
        Log.trace("Division failed: #{reason}", %{:file_name => "Main.hx", :line_number => 227, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    end

    case PositiveInt.safe_div(twenty, three) do
      {:ok, result} ->
        Log.trace("20 / 3 = #{PositiveInt.to_string(result)} (unexpected success)", %{:file_name => "Main.hx", :line_number => 232, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
      {:error, reason} ->
        Log.trace("20 / 3 correctly failed (not exact): #{reason}", %{:file_name => "Main.hx", :line_number => 234, :class_name => "Main", :method_name => "testPositiveIntArithmetic"})
    end
  end

  defp test_non_empty_string_operations() do
    Log.trace("=== NonEmptyString Operations Tests ===", %{:file_name => "Main.hx", :line_number => 242, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    valid_strings = ["hello", "world", "test", "NonEmptyString"]
    Enum.each(valid_strings, fn str ->
      case NonEmptyString.parse(str) do
        {:ok, non_empty} ->
          Log.trace("Valid NonEmptyString: #{NonEmptyString.to_string(non_empty)}", %{:file_name => "Main.hx", :line_number => 247, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
        {:error, reason} ->
          Log.trace("ERROR: Valid string rejected: #{str}, Reason: #{reason}", %{:file_name => "Main.hx", :line_number => 249, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
      end
    end)

    invalid_strings = ["", "   ", "\t\n"]
    Enum.each(invalid_strings, fn str ->
      case NonEmptyString.parse(str) do
        {:ok, _} ->
          Log.trace("ERROR: Empty string parsed successfully: #{inspect(str)}", %{:file_name => "Main.hx", :line_number => 264, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
        {:error, _reason} ->
          :ok  # Expected failure
      end
    end)

    whitespace_strings = ["  hello  ", "\tworld\n", "  test  "]
    Enum.each(whitespace_strings, fn str ->
      case NonEmptyString.parse_and_trim(str) do
        {:ok, trimmed} ->
          Log.trace("Trimmed string: '#{str}' -> '#{NonEmptyString.to_string(trimmed)}'", %{:file_name => "Main.hx", :line_number => 290, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
        {:error, reason} ->
          Log.trace("Failed to trim: #{reason}", %{:file_name => "Main.hx", :line_number => 292, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
      end
    end)

    test_str = ResultTools.unwrap(NonEmptyString.parse("Hello World"))
    starts_with_hello = NonEmptyString.starts_with(test_str, "Hello")
    ends_with_world = NonEmptyString.ends_with(test_str, "World")
    contains_space = NonEmptyString.contains(test_str, " ")
    Log.trace("String operations - Starts with \"Hello\": #{starts_with_hello}, Ends with \"World\": #{ends_with_world}, Contains space: #{contains_space}", %{:file_name => "Main.hx", :line_number => 307, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})

    case NonEmptyString.safe_replace(test_str, "World", "Universe") do
      {:ok, replaced} ->
        Log.trace("Replaced \"World\" with \"Universe\": #{NonEmptyString.to_string(replaced)}", %{:file_name => "Main.hx", :line_number => 312, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
      {:error, reason} ->
        Log.trace("Replacement failed: #{reason}", %{:file_name => "Main.hx", :line_number => 314, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    end

    parts = NonEmptyString.split_non_empty(test_str, " ")
    Log.trace("Split by space: #{length(parts)} parts", %{:file_name => "Main.hx", :line_number => 319, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    Enum.each(parts, fn part ->
      Log.trace("  Part: #{NonEmptyString.to_string(part)}", %{:file_name => "Main.hx", :line_number => 321, :class_name => "Main", :method_name => "testNonEmptyStringOperations"})
    end)
  end

  defp test_functional_composition() do
    Log.trace("=== Functional Composition Tests ===", %{:file_name => "Main.hx", :line_number => 329, :class_name => "Main", :method_name => "testFunctionalComposition"})

    email_chain = ResultTools.unwrap_or(
      ResultTools.map(
        ResultTools.map(
          Email.parse("USER@EXAMPLE.COM"),
          fn email -> Email.normalize(email) end
        ),
        fn email -> Email.get_domain(email) end
      ),
      "unknown"
    )
    Log.trace("Email chain result: #{email_chain}", %{:file_name => "Main.hx", :line_number => 336, :class_name => "Main", :method_name => "testFunctionalComposition"})

    user_id_chain = ResultTools.unwrap_or(
      ResultTools.filter(
        ResultTools.map(
          UserId.parse("TestUser123"),
          fn user_id -> UserId.normalize(user_id) end
        ),
        fn user_id -> UserId.starts_with(user_id, "test") end,
        "UserId does not start with 'test'"
      ),
      ResultTools.unwrap(UserId.parse("defaultuser"))
    )
    Log.trace("UserId chain result: #{UserId.to_string(user_id_chain)}", %{:file_name => "Main.hx", :line_number => 343, :class_name => "Main", :method_name => "testFunctionalComposition"})

    math_chain = ResultTools.unwrap_or(
      ResultTools.map(
        ResultTools.flat_map(
          PositiveInt.parse(10),
          fn n -> PositiveInt.safe_sub(n, ResultTools.unwrap(PositiveInt.parse(3))) end
        ),
        fn n -> PositiveInt.multiply(n, ResultTools.unwrap(PositiveInt.parse(2))) end
      ),
      ResultTools.unwrap(PositiveInt.parse(1))
    )
    Log.trace("Math chain result: #{PositiveInt.to_string(math_chain)}", %{:file_name => "Main.hx", :line_number => 350, :class_name => "Main", :method_name => "testFunctionalComposition"})

    string_chain = ResultTools.unwrap_or(
      ResultTools.flat_map(
        ResultTools.map(
          ResultTools.flat_map(
            NonEmptyString.parse_and_trim("  hello world  "),
            fn s -> NonEmptyString.safe_trim(s) end
          ),
          fn s -> NonEmptyString.to_upper_case(s) end
        ),
        fn s -> NonEmptyString.safe_replace(s, "WORLD", "UNIVERSE") end
      ),
      ResultTools.unwrap(NonEmptyString.parse("fallback"))
    )
    Log.trace("String chain result: #{NonEmptyString.to_string(string_chain)}", %{:file_name => "Main.hx", :line_number => 358, :class_name => "Main", :method_name => "testFunctionalComposition"})

    composition_result = build_user_profile("user123", "  alice@example.com  ", "5")
    case composition_result do
      {:ok, profile} ->
        Log.trace("User profile created successfully:", %{:file_name => "Main.hx", :line_number => 364, :class_name => "Main", :method_name => "testFunctionalComposition"})
        Log.trace("  UserId: #{UserId.to_string(profile.user_id)}", %{:file_name => "Main.hx", :line_number => 365, :class_name => "Main", :method_name => "testFunctionalComposition"})
        Log.trace("  Email: #{Email.to_string(profile.email)}", %{:file_name => "Main.hx", :line_number => 366, :class_name => "Main", :method_name => "testFunctionalComposition"})
        Log.trace("  Score: #{PositiveInt.to_string(profile.score)}", %{:file_name => "Main.hx", :line_number => 367, :class_name => "Main", :method_name => "testFunctionalComposition"})
      {:error, reason} ->
        Log.trace("User profile creation failed: #{reason}", %{:file_name => "Main.hx", :line_number => 369, :class_name => "Main", :method_name => "testFunctionalComposition"})
    end
  end

  defp test_error_handling() do
    Log.trace("=== Error Handling Tests ===", %{:file_name => "Main.hx", :line_number => 377, :class_name => "Main", :method_name => "testErrorHandling"})

    invalid_inputs = [
      %{:email => "invalid-email", :user_id => "ab", :score => "0"},
      %{:email => "user@domain", :user_id => "user@123", :score => "-5"},
      %{:email => "", :user_id => "", :score => "not-a-number"}
    ]

    Enum.each(invalid_inputs, fn input ->
      profile_result = build_user_profile(input.user_id, input.email, input.score)
      case profile_result do
        {:ok, _} ->
          Log.trace("ERROR: Invalid input succeeded: #{inspect(input)}", %{:file_name => "Main.hx", :line_number => 390, :class_name => "Main", :method_name => "testErrorHandling"})
        {:error, reason} ->
          Log.trace("Expected error for invalid input: #{reason}", %{:file_name => "Main.hx", :line_number => 392, :class_name => "Main", :method_name => "testErrorHandling"})
      end
    end)

    Log.trace("Testing edge cases that should succeed:", %{:file_name => "Main.hx", :line_number => 396, :class_name => "Main", :method_name => "testErrorHandling"})

    edge_cases = [
      %{:email => "a@b.co", :user_id => "usr", :score => "1"},
      %{:email => "very.long.email.address@very.long.domain.name.example.com", :user_id => "user123456789", :score => "999"}
    ]

    Enum.each(edge_cases, fn edge_case ->
      profile_result = build_user_profile(edge_case.user_id, edge_case.email, edge_case.score)
      case profile_result do
        {:ok, profile} ->
          Log.trace("Edge case succeeded: UserId=#{UserId.to_string(profile.user_id)}", %{:file_name => "Main.hx", :line_number => 410, :class_name => "Main", :method_name => "testErrorHandling"})
        {:error, reason} ->
          Log.trace("Edge case failed unexpectedly: #{reason}", %{:file_name => "Main.hx", :line_number => 412, :class_name => "Main", :method_name => "testErrorHandling"})
      end
    end)
  end

  defp test_real_world_scenarios() do
    Log.trace("=== Real-World Scenarios ===", %{:file_name => "Main.hx", :line_number => 417, :class_name => "Main", :method_name => "testRealWorldScenarios"})

    registration_data = [
      %{:user_id => "alice123", :email => "alice@example.com", :preferred_name => "Alice Smith"},
      %{:user_id => "bob456", :email => "bob.jones@company.org", :preferred_name => "Bob"},
      %{:user_id => "charlie", :email => "charlie@test.dev", :preferred_name => "Charlie Brown"}
    ]

    valid_users = Enum.reduce(registration_data, [], fn user_data, acc ->
      user_result = create_user(user_data.user_id, user_data.email, user_data.preferred_name)
      case user_result do
        {:ok, user} ->
          Log.trace("Created user: #{UserId.to_string(user.user_id)}", %{:file_name => "Main.hx", :line_number => 433, :class_name => "Main", :method_name => "testRealWorldScenarios"})
          [user | acc]
        {:error, reason} ->
          Log.trace("Failed to create user #{user_data.user_id}: #{reason}", %{:file_name => "Main.hx", :line_number => 436, :class_name => "Main", :method_name => "testRealWorldScenarios"})
          acc
      end
    end)

    Log.trace("Successfully created #{length(valid_users)} users", %{:file_name => "Main.hx", :line_number => 439, :class_name => "Main", :method_name => "testRealWorldScenarios"})

    config_data = [
      %{:timeout => "30", :retries => "3", :name => "production"},
      %{:timeout => "0", :retries => "5", :name => ""},
      %{:timeout => "60", :retries => "-1", :name => "test"}
    ]

    Enum.each(config_data, fn config ->
      config_result = validate_configuration(config.timeout, config.retries, config.name)
      case config_result do
        {:ok, valid_config} ->
          Log.trace("Valid config '#{NonEmptyString.to_string(valid_config.name)}': timeout=#{PositiveInt.to_string(valid_config.timeout)}, retries=#{PositiveInt.to_string(valid_config.retries)}", %{:file_name => "Main.hx", :line_number => 453, :class_name => "Main", :method_name => "testRealWorldScenarios"})
        {:error, reason} ->
          Log.trace("Invalid config: #{reason}", %{:file_name => "Main.hx", :line_number => 455, :class_name => "Main", :method_name => "testRealWorldScenarios"})
      end
    end)
  end

  defp build_user_profile(user_id_str, email_str, score_str) do
    ResultTools.flat_map(
      ResultTools.map_error(UserId.parse(user_id_str), fn e -> "Invalid UserId: #{e}" end),
      fn user_id ->
        ResultTools.flat_map(
          ResultTools.map_error(Email.parse(String.trim(email_str)), fn e -> "Invalid Email: #{e}" end),
          fn email ->
            score_int = String.to_integer(score_str)
            if score_int == nil do
              {:error, "Invalid score: #{score_str}"}
            else
              ResultTools.map(
                ResultTools.map_error(PositiveInt.parse(score_int), fn e -> "Invalid score: #{e}" end),
                fn score ->
                  %{:user_id => user_id, :email => email, :score => score}
                end
              )
            end
          end
        )
      end
    )
  end

  defp create_user(user_id_str, email_str, name_str) do
    ResultTools.flat_map(
      ResultTools.map_error(UserId.parse(user_id_str), fn e -> "Invalid UserId: #{e}" end),
      fn user_id ->
        ResultTools.flat_map(
          ResultTools.map_error(Email.parse(email_str), fn e -> "Invalid Email: #{e}" end),
          fn email ->
            ResultTools.map(
              ResultTools.map_error(NonEmptyString.parse_and_trim(name_str), fn e -> "Invalid Name: #{e}" end),
              fn display_name ->
                %{:user_id => user_id, :email => email, :display_name => display_name}
              end
            )
          end
        )
      end
    )
  end

  defp validate_configuration(timeout_str, retries_str, name_str) do
    with {:ok, timeout_int} <- parse_int_safe(timeout_str, "Timeout"),
         {:ok, retries_int} <- parse_int_safe(retries_str, "Retries"),
         {:ok, timeout} <- ResultTools.map_error(PositiveInt.parse(timeout_int), fn e -> "Invalid timeout: #{e}" end),
         {:ok, retries} <- ResultTools.map_error(PositiveInt.parse(retries_int), fn e -> "Invalid retries: #{e}" end),
         {:ok, name} <- ResultTools.map_error(NonEmptyString.parse_and_trim(name_str), fn e -> "Invalid name: #{e}" end) do
      {:ok, %{:timeout => timeout, :retries => retries, :name => name}}
    else
      error -> error
    end
  end

  defp parse_int_safe(str, field_name) do
    case Integer.parse(str) do
      {n, ""} -> {:ok, n}
      _ -> {:error, "#{field_name} must be a number: #{str}"}
    end
  end
end