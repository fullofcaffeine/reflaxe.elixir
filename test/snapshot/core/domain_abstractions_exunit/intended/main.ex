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
    case valid_email do
      0 -> g_param_0 = elem(valid_email, 1)
    email = g_param_0
    assert Email_Impl_.get_domain(email) == "example.com"
    assert Email_Impl_.get_local_part(email) == "user"
    # Unknown assertion: is_true
    # Unknown assertion: is_false
    normalized = Email_Impl_.normalize(email)
    assert Email_Impl_.to_string(normalized) == "user@example.com"
      1 -> g_param_0 = elem(valid_email, 1)
    reason = g_param_0
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
    case user_id do
      0 -> g_param_0 = elem(user_id, 1)
    id = g_param_0
    Assert.equals("user123", UserId_Impl_.to_string(UserId_Impl_.normalize(id)), "User ID should normalize to lowercase")
    # Unknown assertion: is_true
    # Unknown assertion: is_true
    assert length(UserId_Impl_) == 7
      1 -> g_param_0 = elem(user_id, 1)
    reason = g_param_0
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
      g_param_0 = elem(pos1, 1)
      if ((case pos2 do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0)) do
        g_param_0 = elem(pos2, 1)
        b = g_param_0
        a = g_param_0
        sum = PositiveInt_Impl_.add(a, b)
        assert PositiveInt_Impl_.to_int(sum) == 8
        product = PositiveInt_Impl_.multiply(a, b)
        assert PositiveInt_Impl_.to_int(product) == 15
        diff = PositiveInt_Impl_.safe_sub(a, b)
        # Unknown assertion: is_ok
        case diff do
          0 -> g_param_0 = elem(diff, 1)
        result = g_param_0
        assert PositiveInt_Impl_.to_int(result) == 2
          1 -> g_param_0 = elem(diff, 1)
        reason = g_param_0
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
    case str do
      0 -> g_param_0 = elem(str, 1)
    s = g_param_0
    trimmed = NonEmptyString_Impl_.safe_trim(s)
    # Unknown assertion: is_ok
    case trimmed do
      0 -> g_param_0 = elem(trimmed, 1)
    trimmed_str = g_param_0
    assert NonEmptyString_Impl_.to_string(trimmed_str) == "hello world"
      1 -> g_param_0 = elem(trimmed, 1)
    reason = g_param_0
    flunk("Trim should not fail: " <> reason)
    end
    upper = NonEmptyString_Impl_.to_upper_case(s)
    assert NonEmptyString_Impl_.to_string(upper) == "  HELLO WORLD  "
    lower = NonEmptyString_Impl_.to_lower_case(s)
    assert NonEmptyString_Impl_.to_string(lower) == "  hello world  "
    assert length(NonEmptyString_Impl_) == 15
      1 -> g_param_0 = elem(str, 1)
    reason = g_param_0
    flunk("Valid non-empty string should not fail: " <> reason)
    end
    empty = NonEmptyString_Impl_.parse("")
    # Unknown assertion: is_error
    whitespace_only = NonEmptyString_Impl_.parse("   ")
    # Unknown assertion: is_ok
    case whitespace_only do
      0 -> g_param_0 = elem(whitespace_only, 1)
    ws = g_param_0
    trimmed = NonEmptyString_Impl_.safe_trim(ws)
    # Unknown assertion: is_error
      1 -> g_param_0 = elem(whitespace_only, 1)
    flunk("Whitespace-only should parse")
    end
  end

  test "result chaining" do
    domain_result = ResultTools.filter(ResultTools.map(Email_Impl_.parse("test@example.com"), fn email -> Email_Impl_.get_domain(email) end), fn domain -> (domain == "example.com") end, "Wrong domain")
    # Unknown assertion: is_ok
    case domain_result do
      0 -> g_param_0 = elem(domain_result, 1)
    domain = g_param_0
    assert domain == "example.com"
      1 -> g_param_0 = elem(domain_result, 1)
    reason = g_param_0
    flunk("Domain extraction should not fail: " <> reason)
    end
    failed_filter = ResultTools.filter(ResultTools.map(Email_Impl_.parse("test@wrong.com"), fn email -> Email_Impl_.get_domain(email) end), fn domain -> (domain == "example.com") end, "Wrong domain")
    # Unknown assertion: is_error
  end

  test "option conversion" do
    email_result = Email_Impl_.parse("user@example.com")
    email_option = ResultTools.to_option(email_result)
    # Unknown assertion: is_some
    case email_option do
      0 -> g_param_0 = elem(email_option, 1)
    email = g_param_0
    assert Email_Impl_.get_domain(email) == "example.com"
      1 -> flunk("Valid email should not be :none")
    end
    invalid_email_result = Email_Impl_.parse("invalid")
    invalid_email_option = ResultTools.to_option(invalid_email_result)
    # Unknown assertion: is_none
  end

  test "error handling" do
    invalid_email = Email_Impl_.parse("invalid-email")
    case invalid_email do
      0 -> g_param_0 = elem(invalid_email, 1)
    flunk("Invalid email should not parse")
      1 -> g_param_0 = elem(invalid_email, 1)
    message = g_param_0
    Assert.is_true((message.index_of("Invalid email") >= 0), "Error message should be descriptive")
    end
    large_int = PositiveInt_Impl_.parse(1000000)
    # Unknown assertion: is_ok
    case large_int do
      0 -> g_param_0 = elem(large_int, 1)
    large = g_param_0
    doubled = PositiveInt_Impl_.multiply(large, large)
    Assert.is_true((PositiveInt_Impl_.to_int(doubled) > 0), "Large multiplication should remain positive")
      1 -> g_param_0 = elem(large_int, 1)
    flunk("Large integer should parse")
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
      g_param_0 = elem(user_email, 1)
      if ((case user_id do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0)) do
        g_param_0 = elem(user_id, 1)
        if ((case user_age do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0)) do
          g_param_0 = elem(user_age, 1)
          if ((case user_name do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0)) do
            g_param_0 = elem(user_name, 1)
            name = g_param_0
            id = g_param_0
            email = g_param_0
            age = g_param_0
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
