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
    assert ResultTools.is_ok(valid_email)
    case (case valid_email do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case valid_email do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        email = _g
        assert Email_Impl_.getDomain(email) == "example.com"
        assert Email_Impl_.getLocalPart(email) == "user"
        assert Email_Impl_.hasDomain(email, "example.com")
        refute Email_Impl_.hasDomain(email, "other.com")
        normalized = Email_Impl_.normalize(email)
        assert Email_Impl_.toString(normalized) == "user@example.com"
      1 ->
        _g = case valid_email do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        flunk("Valid email should not fail: " <> reason)
    end
    invalid_email = Email_Impl_.parse("not-an-email")
    assert ResultTools.is_error(invalid_email)
    empty_email = Email_Impl_.parse("")
    assert ResultTools.is_error(empty_email)
  end

  test "user id validation" do
    user_id = UserId_Impl_.parse("User123")
    assert ResultTools.is_ok(user_id)
    case (case user_id do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case user_id do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        id = _g
        Assert.equals("user123", UserId_Impl_.toString(UserId_Impl_.normalize(id)), "User ID should normalize to lowercase")
        assert UserId_Impl_.startsWith(id, "User")
        assert UserId_Impl_.startsWithIgnoreCase(id, "user")
        assert length(UserId_Impl_) == 7
      1 ->
        _g = case user_id do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        flunk("Valid user ID should not fail: " <> reason)
    end
    empty_user_id = UserId_Impl_.parse("")
    assert ResultTools.is_error(empty_user_id)
    invalid_user_id = UserId_Impl_.parse("user@123")
    assert ResultTools.is_error(invalid_user_id)
  end

  test "positive int arithmetic" do
    pos1 = PositiveInt_Impl_.parse(5)
    pos2 = PositiveInt_Impl_.parse(3)
    assert ResultTools.is_ok(pos1)
    assert ResultTools.is_ok(pos2)
    if (case pos1 do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0) do
      _g = case pos1 do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      if (case pos2 do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0) do
        _g = case pos2 do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        b = _g
        a = _g
        sum = PositiveInt_Impl_.add(a, b)
        assert PositiveInt_Impl_.toInt(sum) == 8
        product = PositiveInt_Impl_.multiply(a, b)
        assert PositiveInt_Impl_.toInt(product) == 15
        diff = PositiveInt_Impl_.safeSub(a, b)
        assert ResultTools.is_ok(diff)
        case (case diff do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            _g = case diff do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            result = _g
            assert PositiveInt_Impl_.toInt(result) == 2
          1 ->
            _g = case diff do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = _g
            flunk("Subtraction should not fail: " <> reason)
        end
        invalid_diff = PositiveInt_Impl_.safeSub(b, a)
        assert ResultTools.is_error(invalid_diff)
      else
        flunk("Valid positive integers should parse")
      end
    else
      flunk("Valid positive integers should parse")
    end
    zero = PositiveInt_Impl_.parse(0)
    assert ResultTools.is_error(zero)
    negative = PositiveInt_Impl_.parse(-5)
    assert ResultTools.is_error(negative)
  end

  test "non empty string operations" do
    str = NonEmptyString_Impl_.parse("  hello world  ")
    assert ResultTools.is_ok(str)
    case (case str do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case str do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        s = _g
        trimmed = NonEmptyString_Impl_.safeTrim(s)
        assert ResultTools.is_ok(trimmed)
        case (case trimmed do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            _g = case trimmed do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            trimmed_str = _g
            assert NonEmptyString_Impl_.toString(trimmed_str) == "hello world"
          1 ->
            _g = case trimmed do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = _g
            flunk("Trim should not fail: " <> reason)
        end
        upper = NonEmptyString_Impl_.toUpperCase(s)
        assert NonEmptyString_Impl_.toString(upper) == "  HELLO WORLD  "
        lower = NonEmptyString_Impl_.toLowerCase(s)
        assert NonEmptyString_Impl_.toString(lower) == "  hello world  "
        assert length(NonEmptyString_Impl_) == 15
      1 ->
        _g = case str do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        flunk("Valid non-empty string should not fail: " <> reason)
    end
    empty = NonEmptyString_Impl_.parse("")
    assert ResultTools.is_error(empty)
    whitespace_only = NonEmptyString_Impl_.parse("   ")
    assert ResultTools.is_ok(whitespace_only)
    case (case whitespace_only do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case whitespace_only do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        ws = _g
        trimmed = NonEmptyString_Impl_.safeTrim(ws)
        assert ResultTools.is_error(trimmed)
      1 ->
        case whitespace_only do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        flunk("Whitespace-only should parse")
    end
  end

  test "result chaining" do
    domain_result = ResultTools.filter(ResultTools.map(Email_Impl_.parse("test@example.com"), fn email -> Email_Impl_.getDomain(email) end), fn domain -> domain == "example.com" end, "Wrong domain")
    assert ResultTools.is_ok(domain_result)
    case (case domain_result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case domain_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        domain = _g
        assert domain == "example.com"
      1 ->
        _g = case domain_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        flunk("Domain extraction should not fail: " <> reason)
    end
    failed_filter = ResultTools.filter(ResultTools.map(Email_Impl_.parse("test@wrong.com"), fn email -> Email_Impl_.getDomain(email) end), fn domain -> domain == "example.com" end, "Wrong domain")
    assert ResultTools.is_error(failed_filter)
  end

  test "option conversion" do
    email_result = Email_Impl_.parse("user@example.com")
    email_option = ResultTools.toOption(email_result)
    assert OptionTools.is_some(email_option)
    case (case email_option do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 ->
        _g = case email_option do {:ok, value} -> value; :error -> nil; _ -> nil end
        email = _g
        assert Email_Impl_.getDomain(email) == "example.com"
      1 ->
        flunk("Valid email should not be :none")
    end
    invalid_email_result = Email_Impl_.parse("invalid")
    invalid_email_option = ResultTools.toOption(invalid_email_result)
    assert OptionTools.is_none(invalid_email_option)
  end

  test "error handling" do
    invalid_email = Email_Impl_.parse("invalid-email")
    case (case invalid_email do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case invalid_email do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        flunk("Invalid email should not parse")
      1 ->
        _g = case invalid_email do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        message = _g
        assert case :binary.match(message, "Invalid email") do {pos, _} -> pos; :nomatch -> -1 end >= 0
    end
    large_int = PositiveInt_Impl_.parse(1000000)
    assert ResultTools.is_ok(large_int)
    case (case large_int do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case large_int do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        large = _g
        doubled = PositiveInt_Impl_.multiply(large, large)
        assert PositiveInt_Impl_.toInt(doubled) > 0
      1 ->
        case large_int do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        flunk("Large integer should parse")
    end
  end

  test "real world scenario" do
    user_email = Email_Impl_.parse("john.doe@company.com")
    user_id = UserId_Impl_.parse("johndoe123")
    user_age = PositiveInt_Impl_.parse(25)
    user_name = NonEmptyString_Impl_.parse("John Doe")
    assert ResultTools.is_ok(user_email)
    assert ResultTools.is_ok(user_id)
    assert ResultTools.is_ok(user_age)
    assert ResultTools.is_ok(user_name)
    if (case user_email do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0) do
      _g = case user_email do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
      if (case user_id do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0) do
        _g = case user_id do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        if (case user_age do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0) do
          _g = case user_age do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
          if (case user_name do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end == 0) do
            _g = case user_name do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            name = _g
            id = _g
            email = _g
            age = _g
            profile_normalized_id = nil
            profile_is_company_email = nil
            profile_email = nil
            profile_display_name = nil
            profile_age_in_months = nil
            profile_email = Email_Impl_.toString(email)
            profile_normalized_id = UserId_Impl_.toString(UserId_Impl_.normalize(id))
            profile_is_company_email = Email_Impl_.hasDomain(email, "company.com")
            profile_age_in_months = PositiveInt_Impl_.toInt(age) * 12
            profile_display_name = NonEmptyString_Impl_.toString(name)
            assert profile_email == "john.doe@company.com"
            assert profile_normalized_id == "johndoe123"
            assert profile_is_company_email
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
