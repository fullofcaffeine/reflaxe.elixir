defmodule Main do
  use ExUnit.Case
  test "email validation" do
    valid_email = Email_Impl_.parse("user@example.com")
    assert match?({:ok, _}, valid_email)
    (case valid_email do
      {:ok, value} ->
        assert actual == "example.com"
        assert actual == "user"
        assert condition
        assert not condition
        normalized = Email_Impl_.normalize(email)
        assert actual == "user@example.com"
      {:error, reason} -> flunk("Valid email should not fail: " <> reason)
    end)
    invalid_email = Email_Impl_.parse("not-an-email")
    assert match?({:error, _}, invalid_email)
    empty_email = Email_Impl_.parse("")
    assert match?({:error, _}, empty_email)
  end
  test "user id validation" do
    user_id = UserId_Impl_.parse("User123")
    assert match?({:ok, _}, user_id)
    (case user_id do
      {:ok, value} ->
        assert actual == "user123"
        assert condition
        assert condition
        assert actual == 7
      {:error, reason} -> flunk("Valid user ID should not fail: " <> reason)
    end)
    empty_user_id = UserId_Impl_.parse("")
    assert match?({:error, _}, empty_user_id)
    invalid_user_id = UserId_Impl_.parse("user@123")
    assert match?({:error, _}, invalid_user_id)
  end
  test "positive int arithmetic" do
    pos1 = PositiveInt_Impl_.parse(5)
    pos2 = PositiveInt_Impl_.parse(3)
    assert match?({:ok, _}, pos1)
    assert match?({:ok, _}, pos2)
    (case pos1 do
      {:ok, _} ->
        (case pos2 do
          {:ok, _} ->
            b = _g1
            a = _g
            sum = PositiveInt_Impl_.add(a, b)
            actual = PositiveInt_Impl_.to_int(sum)
            assert actual == 8
            product = PositiveInt_Impl_.multiply(a, b)
            actual = PositiveInt_Impl_.to_int(product)
            assert actual == 15
            diff = PositiveInt_Impl_.safe_sub(a, b)
            assert match?({:ok, _}, diff)
            (case diff do
              {:ok, value} -> assert actual == 2
              {:error, reason} -> flunk("Subtraction should not fail: " <> reason)
            end)
            invalid_diff = PositiveInt_Impl_.safe_sub(b, a)
            assert match?({:error, _}, invalid_diff)
          _ -> flunk("Valid positive integers should parse")
        end)
      _ -> flunk("Valid positive integers should parse")
    end)
    zero = PositiveInt_Impl_.parse(0)
    assert match?({:error, _}, zero)
    negative = PositiveInt_Impl_.parse(-5)
    assert match?({:error, _}, negative)
  end
  test "non empty string operations" do
    str = NonEmptyString_Impl_.parse("  hello world  ")
    assert match?({:ok, _}, str)
    (case str do
      {:ok, value} ->
        trimmed = NonEmptyString_Impl_.safe_trim(s)
        assert match?({:ok, _}, trimmed)
        (case trimmed do
          {:ok, value} -> assert actual == "hello world"
          {:error, reason} -> flunk("Trim should not fail: " <> reason)
        end)
        upper = NonEmptyString_Impl_.to_upper_case(s)
        actual = NonEmptyString_Impl_.to_string(upper)
        assert actual == "  HELLO WORLD  "
        lower = NonEmptyString_Impl_.to_lower_case(s)
        actual = NonEmptyString_Impl_.to_string(lower)
        assert actual == "  hello world  "
        actual = NonEmptyString_Impl_.length(s)
        assert actual == 15
      {:error, reason} -> flunk("Valid non-empty string should not fail: " <> reason)
    end)
    empty = NonEmptyString_Impl_.parse("")
    assert match?({:error, _}, empty)
    whitespace_only = NonEmptyString_Impl_.parse("   ")
    assert match?({:ok, _}, whitespace_only)
    (case whitespace_only do
      {:ok, value} ->
        trimmed = NonEmptyString_Impl_.safe_trim(ws)
        assert match?({:error, _}, trimmed)
      {:error, whitespace_only} -> flunk("Whitespace-only should parse")
    end)
  end
  test "result chaining" do
    domain_result = ResultTools.filter(ResultTools.map(Email_Impl_.parse("test@example.com"), fn email -> Email_Impl_.get_domain(email) end), fn domain -> domain == "example.com" end, "Wrong domain")
    assert match?({:ok, _}, domain_result)
    (case domain_result do
      {:ok, value} -> assert domain == "example.com"
      {:error, reason} -> flunk("Domain extraction should not fail: " <> reason)
    end)
    failed_filter = ResultTools.filter(ResultTools.map(Email_Impl_.parse("test@wrong.com"), fn email -> Email_Impl_.get_domain(email) end), fn domain -> domain == "example.com" end, "Wrong domain")
    assert match?({:error, _}, failed_filter)
  end
  test "option conversion" do
    email_result = Email_Impl_.parse("user@example.com")
    email_option = ResultTools.to_option(email_result)
    assert match?({:some, _}, email_option)
    (case email_option do
      {:some, actual} -> assert actual == "example.com"
      {:none} -> flunk("Valid email should not be None")
    end)
    invalid_email_result = Email_Impl_.parse("invalid")
    invalid_email_option = ResultTools.to_option(invalid_email_result)
    assert invalid_email_option == :none
  end
  test "error handling" do
    invalid_email = Email_Impl_.parse("invalid-email")
    (case invalid_email do
      {:ok, invalid_email} -> flunk("Invalid email should not parse")
      {:error, reason} -> assert condition
    end)
    large_int = PositiveInt_Impl_.parse(1000000)
    assert match?({:ok, _}, large_int)
    (case large_int do
      {:ok, value} ->
        doubled = PositiveInt_Impl_.multiply(large, large)
        assert condition
      {:error, large_int} -> flunk("Large integer should parse")
    end)
  end
  test "real world scenario" do
    user_email = Email_Impl_.parse("john.doe@company.com")
    user_id = UserId_Impl_.parse("johndoe123")
    user_age = PositiveInt_Impl_.parse(25)
    user_name = NonEmptyString_Impl_.parse("John Doe")
    assert match?({:ok, _}, user_email)
    assert match?({:ok, _}, user_id)
    assert match?({:ok, _}, user_age)
    assert match?({:ok, _}, user_name)
    (case user_email do
      {:ok, _} ->
        (case user_id do
          {:ok, _} ->
            (case user_age do
              {:ok, _} ->
                (case user_name do
                  {:ok, _} ->
                    name = _g3
                    id = _g1
                    email = _g
                    age = _g2
                    profile_normalized_id = nil
                    profile_is_company_email = nil
                    profile_email = nil
                    profile_display_name = nil
                    profile_age_in_months = nil
                    profile_email = Email_Impl_.to_string(email)
                    profile_normalized_id = UserId_Impl_.to_string(UserId_Impl_.normalize(id))
                    profile_is_company_email = Email_Impl_.has_domain(email, "company.com")
                    profile_age_in_months = PositiveInt_Impl_.to_int(age) * 12
                    profile_display_name = NonEmptyString_Impl_.to_string(name)
                    actual = profile_email
                    assert actual == "john.doe@company.com"
                    actual = profile_normalized_id
                    assert actual == "johndoe123"
                    condition = profile_is_company_email
                    assert condition
                    actual = profile_display_name
                    assert actual == "John Doe"
                  _ -> flunk("All user data should be valid")
                end)
              _ -> flunk("All user data should be valid")
            end)
          _ -> flunk("All user data should be valid")
        end)
      _ -> flunk("All user data should be valid")
    end)
  end
end
