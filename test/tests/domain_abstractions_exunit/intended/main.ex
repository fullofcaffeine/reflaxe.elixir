defmodule Main do
  use ExUnit.Case

  @moduledoc """
  
 * Comprehensive ExUnit tests for domain abstractions.
 * 
 * This test suite validates that our domain abstractions:
 * - Compile to proper Elixir ExUnit tests
 * - Provide type-safe validation and operations
 * - Generate idiomatic Elixir code with proper pattern matching
 * - Work correctly with Result and Option types
 * 
 * These tests are written in Haxe and compile to ExUnit tests,
 * maintaining the "write once in Haxe" philosophy.
 
  """

  test "email validation" do
    valid_email = Email_Impl_.parse("user@example.com")
    # Unknown assertion: is_ok
    case (case valid_email do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, email} -> g_array = elem(validEmail, 1)
    assert Email_Impl_.get_domain(email) == "example.com"
    assert Email_Impl_.get_local_part(email) == "user"
    # Unknown assertion: is_true
    # Unknown assertion: is_false
    normalized = Email_Impl_.normalize(email)
    assert Email_Impl_.to_string(normalized) == "user@example.com"
      {1, reason} -> g_array = elem(validEmail, 1)
    flunk("Valid email should not fail: " <> reason)
    end
    invalid_email = Email_Impl_.parse("not-an-email")
    # Unknown assertion: is_error
    empty_email = Email_Impl_.parse("")
    # Unknown assertion: is_error
  end

  test "user id validation" do
    user_id = UserId_Impl_.parse("User123")
    # Unknown assertion: is_ok
    case (case user_id do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, id} -> g_array = elem(userId, 1)
    Assert.equals("user123", UserId_Impl_.to_string(UserId_Impl_.normalize(id)), "User ID should normalize to lowercase")
    # Unknown assertion: is_true
    # Unknown assertion: is_true
    assert length(UserId_Impl_) == 7
      {1, reason} -> g_array = elem(userId, 1)
    flunk("Valid user ID should not fail: " <> reason)
    end
    empty_user_id = UserId_Impl_.parse("")
    # Unknown assertion: is_error
    invalid_user_id = UserId_Impl_.parse("user@123")
    # Unknown assertion: is_error
  end

  test "positive int arithmetic" do
    pos1 = PositiveInt_Impl_.parse(5)
    pos2 = PositiveInt_Impl_.parse(3)
    # Unknown assertion: is_ok
    # Unknown assertion: is_ok
    if ((case pos1 do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0)) do
      g_array = elem(pos1, 1)
      if ((case pos2 do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0)) do
        g_array = elem(pos2, 1)
        b = g_array
        a = g_array
        sum = PositiveInt_Impl_.add(a, b)
        assert PositiveInt_Impl_.to_int(sum) == 8
        product = PositiveInt_Impl_.multiply(a, b)
        assert PositiveInt_Impl_.to_int(product) == 15
        diff = PositiveInt_Impl_.safe_sub(a, b)
        # Unknown assertion: is_ok
        case (case diff do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          {0, result} -> g_array = elem(diff, 1)
        assert PositiveInt_Impl_.to_int(result) == 2
          {1, reason} -> g_array = elem(diff, 1)
        flunk("Subtraction should not fail: " <> reason)
        end
        invalid_diff = PositiveInt_Impl_.safe_sub(b, a)
        # Unknown assertion: is_error
      else
        flunk("Valid positive integers should parse")
      end
    else
      flunk("Valid positive integers should parse")
    end
    zero = PositiveInt_Impl_.parse(0)
    # Unknown assertion: is_error
    negative = PositiveInt_Impl_.parse(-5)
    # Unknown assertion: is_error
  end

  test "non empty string operations" do
    str = NonEmptyString_Impl_.parse("  hello world  ")
    # Unknown assertion: is_ok
    case (case str do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, s} -> g_array = elem(str, 1)
    trimmed = NonEmptyString_Impl_.safe_trim(s)
    # Unknown assertion: is_ok
    case (case trimmed do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, _trimmed_str} -> g_array = elem(trimmed, 1)
    assert NonEmptyString_Impl_.to_string(trimmed_str) == "hello world"
      {1, reason} -> g_array = elem(trimmed, 1)
    flunk("Trim should not fail: " <> reason)
    end
    upper = NonEmptyString_Impl_.to_upper_case(s)
    assert NonEmptyString_Impl_.to_string(upper) == "  HELLO WORLD  "
    lower = NonEmptyString_Impl_.to_lower_case(s)
    assert NonEmptyString_Impl_.to_string(lower) == "  hello world  "
    assert length(NonEmptyString_Impl_) == 15
      {1, reason} -> g_array = elem(str, 1)
    flunk("Valid non-empty string should not fail: " <> reason)
    end
    empty = NonEmptyString_Impl_.parse("")
    # Unknown assertion: is_error
    whitespace_only = NonEmptyString_Impl_.parse("   ")
    # Unknown assertion: is_ok
    case (case whitespace_only do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, ws} -> g_array = elem(whitespaceOnly, 1)
    trimmed = NonEmptyString_Impl_.safe_trim(ws)
    # Unknown assertion: is_error
      1 -> flunk("Whitespace-only should parse")
    end
  end

  test "result chaining" do
    domain_result = ResultTools.filter(ResultTools.map(Email_Impl_.parse("test@example.com"), fn email -> Email_Impl_.get_domain(email) end), fn domain -> (domain == "example.com") end, "Wrong domain")
    # Unknown assertion: is_ok
    case (case domain_result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, domain} -> g_array = elem(domainResult, 1)
    assert domain == "example.com"
      {1, reason} -> g_array = elem(domainResult, 1)
    flunk("Domain extraction should not fail: " <> reason)
    end
    failed_filter = ResultTools.filter(ResultTools.map(Email_Impl_.parse("test@wrong.com"), fn email -> Email_Impl_.get_domain(email) end), fn domain -> (domain == "example.com") end, "Wrong domain")
    # Unknown assertion: is_error
  end

  test "option conversion" do
    email_result = Email_Impl_.parse("user@example.com")
    email_option = ResultTools.to_option(email_result)
    # Unknown assertion: is_some
    case (case email_option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, email} -> g_array = elem(emailOption, 1)
    assert Email_Impl_.get_domain(email) == "example.com"
      1 -> flunk("Valid email should not be :none")
    end
    invalid_email_result = Email_Impl_.parse("invalid")
    invalid_email_option = ResultTools.to_option(invalid_email_result)
    # Unknown assertion: is_none
  end

  test "error handling" do
    invalid_email = Email_Impl_.parse("invalid-email")
    case (case invalid_email do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 -> flunk("Invalid email should not parse")
      {1, message} -> g_array = elem(invalidEmail, 1)
    Assert.is_true((message.index_of("Invalid email") >= 0), "Error message should be descriptive")
    end
    large_int = PositiveInt_Impl_.parse(1000000)
    # Unknown assertion: is_ok
    case (case large_int do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      {0, large} -> g_array = elem(largeInt, 1)
    doubled = PositiveInt_Impl_.multiply(large, large)
    Assert.is_true((PositiveInt_Impl_.to_int(doubled) > 0), "Large multiplication should remain positive")
      1 -> flunk("Large integer should parse")
    end
  end

  test "real world scenario" do
    user_email = Email_Impl_.parse("john.doe@company.com")
    user_id = UserId_Impl_.parse("johndoe123")
    user_age = PositiveInt_Impl_.parse(25)
    user_name = NonEmptyString_Impl_.parse("John Doe")
    # Unknown assertion: is_ok
    # Unknown assertion: is_ok
    # Unknown assertion: is_ok
    # Unknown assertion: is_ok
    if ((case user_email do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0)) do
      g_array = elem(userEmail, 1)
      if ((case user_id do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0)) do
        g_array = elem(userId, 1)
        if ((case user_age do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0)) do
          g_array = elem(userAge, 1)
          if ((case user_name do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0)) do
            g_array = elem(userName, 1)
            name = g_array
            id = g_array
            email = g_array
            age = g_array
            profile_normalized_id = nil
            profile_is_company_email = nil
            profile_email = nil
            profile_display_name = nil
            profile_age_in_months = nil
            profile_email = Email_Impl_.to_string(email)
            profile_normalized_id = UserId_Impl_.to_string(UserId_Impl_.normalize(id))
            profile_is_company_email = Email_Impl_.has_domain(email, "company.com")
            profile_age_in_months = (PositiveInt_Impl_.to_int(age) * 12)
            profile_display_name = NonEmptyString_Impl_.to_string(name)
            assert profile_email == "john.doe@company.com"
            assert profile_normalized_id == "johndoe123"
            # Unknown assertion: is_true
            assert profile_display_name == "John Doe"
          else
            flunk("All user data should be valid")
          end
        else
          flunk("All user data should be valid")
        end
      else
        flunk("All user data should be valid")
      end
    else
      flunk("All user data should be valid")
    end
  end

end
