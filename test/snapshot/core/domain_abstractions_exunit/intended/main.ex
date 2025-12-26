defmodule Main do
  use ExUnit.Case
  test "email validation" do
    valid_email = MyApp.Email_Impl_.parse("user@example.com")
    assert match?({:ok, _}, valid_email)
    (case valid_email do
      {:ok, email} ->
        actual = MyApp.Email_Impl_.get_domain(email)
        assert actual == "example.com"
        actual = MyApp.Email_Impl_.get_local_part(email)
        assert actual == "user"
        condition = MyApp.Email_Impl_.has_domain(email, "example.com")
        assert condition
        condition = MyApp.Email_Impl_.has_domain(email, "other.com")
        assert not condition
        normalized = MyApp.Email_Impl_.normalize(email)
        actual = MyApp.Email_Impl_.to_string(normalized)
        assert actual == "user@example.com"
      {:error, reason} -> flunk("Valid email should not fail: " <> reason)
    end)
    invalid_email = MyApp.Email_Impl_.parse("not-an-email")
    assert match?({:error, _}, invalid_email)
    empty_email = MyApp.Email_Impl_.parse("")
    assert match?({:error, _}, empty_email)
  end
  test "user id validation" do
    user_id = MyApp.UserId_Impl_.parse("User123")
    assert match?({:ok, _}, user_id)
    (case user_id do
      {:ok, id} ->
        actual = MyApp.UserId_Impl_.to_string(MyApp.UserId_Impl_.normalize(id))
        assert actual == "user123"
        condition = MyApp.UserId_Impl_.starts_with(id, "User")
        assert condition
        condition = MyApp.UserId_Impl_.starts_with_ignore_case(id, "user")
        assert condition
        actual = MyApp.UserId_Impl_.length(id)
        assert actual == 7
      {:error, reason} -> flunk("Valid user ID should not fail: " <> reason)
    end)
    empty_user_id = MyApp.UserId_Impl_.parse("")
    assert match?({:error, _}, empty_user_id)
    invalid_user_id = MyApp.UserId_Impl_.parse("user@123")
    assert match?({:error, _}, invalid_user_id)
  end
  test "positive int arithmetic" do
    pos1 = MyApp.PositiveInt_Impl_.parse(5)
    pos2 = MyApp.PositiveInt_Impl_.parse(3)
    assert match?({:ok, _}, pos1)
    assert match?({:ok, _}, pos2)
    (case pos1 do
      {:ok, a} ->
        b = a
        pos2 = a
        (case pos2 do
          {:ok, b} ->
            result = b
            a = b
            sum = MyApp.PositiveInt_Impl_.add(a, b)
            actual = MyApp.PositiveInt_Impl_.to_int(sum)
            assert actual == 8
            product = MyApp.PositiveInt_Impl_.multiply(a, b)
            actual = MyApp.PositiveInt_Impl_.to_int(product)
            assert actual == 15
            diff = MyApp.PositiveInt_Impl_.safe_sub(a, b)
            assert match?({:ok, _}, diff)
            (case diff do
              {:ok, result} ->
                actual = MyApp.PositiveInt_Impl_.to_int(result)
                assert actual == 2
              {:error, reason} -> flunk("Subtraction should not fail: " <> reason)
            end)
            invalid_diff = MyApp.PositiveInt_Impl_.safe_sub(b, a)
            assert match?({:error, _}, invalid_diff)
          _ -> flunk("Valid positive integers should parse")
        end)
      _ -> flunk("Valid positive integers should parse")
    end)
    zero = MyApp.PositiveInt_Impl_.parse(0)
    assert match?({:error, _}, zero)
    negative = MyApp.PositiveInt_Impl_.parse(-5)
    assert match?({:error, _}, negative)
  end
  test "non empty string operations" do
    str = MyApp.NonEmptyString_Impl_.parse("  hello world  ")
    assert match?({:ok, _}, str)
    (case str do
      {:ok, value} ->
        trimmed_str = value
        s = value
        trimmed = MyApp.NonEmptyString_Impl_.safe_trim(s)
        assert match?({:ok, _}, trimmed)
        (case trimmed do
          {:ok, trimmed_str} ->
            actual = MyApp.NonEmptyString_Impl_.to_string(trimmed_str)
            assert actual == "hello world"
          {:error, reason} -> flunk("Trim should not fail: " <> reason)
        end)
        upper = MyApp.NonEmptyString_Impl_.to_upper_case(s)
        actual = MyApp.NonEmptyString_Impl_.to_string(upper)
        assert actual == "  HELLO WORLD  "
        lower = MyApp.NonEmptyString_Impl_.to_lower_case(s)
        actual = MyApp.NonEmptyString_Impl_.to_string(lower)
        assert actual == "  hello world  "
        actual = MyApp.NonEmptyString_Impl_.length(s)
        assert actual == 15
      {:error, reason} -> flunk("Valid non-empty string should not fail: " <> reason)
    end)
    empty = MyApp.NonEmptyString_Impl_.parse("")
    assert match?({:error, _}, empty)
    whitespace_only = MyApp.NonEmptyString_Impl_.parse("   ")
    assert match?({:ok, _}, whitespace_only)
    (case whitespace_only do
      {:ok, ws} ->
        trimmed = MyApp.NonEmptyString_Impl_.safe_trim(ws)
        assert match?({:error, _}, trimmed)
      {:error, _error} -> flunk("Whitespace-only should parse")
    end)
  end
  test "result chaining" do
    domain_result = MyApp.ResultTools.filter(MyApp.ResultTools.map(MyApp.Email_Impl_.parse("test@example.com"), fn email -> MyApp.Email_Impl_.get_domain(email) end), fn domain -> domain == "example.com" end, "Wrong domain")
    assert match?({:ok, _}, domain_result)
    (case domain_result do
      {:ok, _value} -> assert domain == "example.com"
      {:error, reason} -> flunk("Domain extraction should not fail: " <> reason)
    end)
    failed_filter = MyApp.ResultTools.filter(MyApp.ResultTools.map(MyApp.Email_Impl_.parse("test@wrong.com"), fn email -> MyApp.Email_Impl_.get_domain(email) end), fn domain -> domain == "example.com" end, "Wrong domain")
    assert match?({:error, _}, failed_filter)
  end
  test "option conversion" do
    email_result = MyApp.Email_Impl_.parse("user@example.com")
    email_option = MyApp.ResultTools.to_option(email_result)
    assert match?({:some, _}, email_option)
    (case email_option do
      {:some, v} ->
        email = v
        actual = MyApp.Email_Impl_.get_domain(email)
        assert actual == "example.com"
      {:none} -> flunk("Valid email should not be None")
    end)
    invalid_email_result = MyApp.Email_Impl_.parse("invalid")
    invalid_email_option = MyApp.ResultTools.to_option(invalid_email_result)
    assert invalid_email_option == :none
  end
  test "error handling" do
    invalid_email = MyApp.Email_Impl_.parse("invalid-email")
    (case invalid_email do
      {:ok, _value} -> flunk("Invalid email should not parse")
      {:error, message} ->
        condition = case :binary.match(message, "Invalid email") do
                {pos, _} -> pos
                :nomatch -> -1
            end >= 0
        assert condition
    end)
    large_int = MyApp.PositiveInt_Impl_.parse(1000000)
    assert match?({:ok, _}, large_int)
    (case large_int do
      {:ok, large} ->
        doubled = MyApp.PositiveInt_Impl_.multiply(large, large)
        condition = MyApp.PositiveInt_Impl_.to_int(doubled) > 0
        assert condition
      {:error, _error} -> flunk("Large integer should parse")
    end)
  end
  test "real world scenario" do
    user_email = MyApp.Email_Impl_.parse("john.doe@company.com")
    user_id = MyApp.UserId_Impl_.parse("johndoe123")
    user_age = MyApp.PositiveInt_Impl_.parse(25)
    user_name = MyApp.NonEmptyString_Impl_.parse("John Doe")
    assert match?({:ok, _}, user_email)
    assert match?({:ok, _}, user_id)
    assert match?({:ok, _}, user_age)
    assert match?({:ok, _}, user_name)
    (case user_email do
      {:ok, email} ->
        user_id = email
        (case user_id do
          {:ok, id} ->
            user_age = id
            (case user_age do
              {:ok, age} ->
                name = age
                user_name = age
                (case user_name do
                  {:ok, name} ->
                    id = name
                    email = name
                    age = name
                    profile_normalized_id = nil
                    profile_is_company_email = nil
                    profile_email = nil
                    profile_display_name = nil
                    profile_age_in_months = nil
                    profile_email = MyApp.Email_Impl_.to_string(email)
                    profile_normalized_id = MyApp.UserId_Impl_.to_string(MyApp.UserId_Impl_.normalize(id))
                    profile_is_company_email = MyApp.Email_Impl_.has_domain(email, "company.com")
                    profile_age_in_months = MyApp.PositiveInt_Impl_.to_int(age) * 12
                    profile_display_name = MyApp.NonEmptyString_Impl_.to_string(name)
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
