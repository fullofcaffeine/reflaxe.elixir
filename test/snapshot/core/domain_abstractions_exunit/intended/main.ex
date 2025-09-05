defmodule Main do
  use ExUnit.Case
  test "email validation" do
    valid_email = {:Parse, "user@example.com"}
    assert match?({:ok, _}, valid_email) do
      "Valid email should parse successfully"
    end
    case (elem(valid_email, 0)) do
      0 ->
        g = elem(valid_email, 1)
        email = g
        assert "example.com" == Email_Impl_.get_domain(email) do
          "Domain extraction should work"
        end
        assert "user" == Email_Impl_.get_local_part(email) do
          "Local part extraction should work"
        end
        assert Email_Impl_.has_domain(email, "example.com") do
          "Domain check should return true"
        end
        refute Email_Impl_.has_domain(email, "other.com") do
          "Domain check should return false for different domain"
        end
        normalized = Email_Impl_.normalize(email)
        assert "user@example.com" == Email_Impl_.to_string(normalized) do
          "Normalization should lowercase"
        end
      1 ->
        g = elem(valid_email, 1)
        reason = g
        flunk("Valid email should not fail: " <> reason)
    end
    invalid_email = {:Parse, "not-an-email"}
    assert match?({:error, _}, invalid_email) do
      "Invalid email should be rejected"
    end
    empty_email = {:Parse, ""}
    assert match?({:error, _}, empty_email) do
      "Empty email should be rejected"
    end
  end
  test "user id validation" do
    user_id = {:Parse, "User123"}
    assert match?({:ok, _}, user_id) do
      "Valid user ID should parse"
    end
    case (elem(user_id, 0)) do
      0 ->
        g = elem(user_id, 1)
        id = g
        assert "user123" == UserId_Impl_.to_string(UserId_Impl_.normalize(id)) do
          "User ID should normalize to lowercase"
        end
        assert UserId_Impl_.starts_with(id, "User") do
          "User ID should support startsWith check"
        end
        assert UserId_Impl_.starts_with_ignore_case(id, "user") do
          "User ID should support case-insensitive startsWith"
        end
        assert 7 == UserId_Impl_.length(id) do
          "User ID length should be preserved"
        end
      1 ->
        g = elem(user_id, 1)
        reason = g
        flunk("Valid user ID should not fail: " <> reason)
    end
    empty_user_id = {:Parse, ""}
    assert match?({:error, _}, empty_user_id) do
      "Empty user ID should be rejected"
    end
    invalid_user_id = {:Parse, "user@123"}
    assert match?({:error, _}, invalid_user_id) do
      "User ID with special characters should be rejected"
    end
  end
  test "positive int arithmetic" do
    pos1 = {:Parse, 5}
    pos2 = {:Parse, 3}
    assert match?({:ok, _}, pos1) do
      "Positive integer 5 should parse"
    end
    assert match?({:ok, _}, pos2) do
      "Positive integer 3 should parse"
    end
    if (elem(pos1, 0) == 0) do
      g = elem(pos1, 1)
      if (elem(pos2, 0) == 0) do
        g1 = elem(pos2, 1)
        b = g1
        a = g
        sum = PositiveInt_Impl_.add(a, b)
        assert 8 == PositiveInt_Impl_.to_int(sum) do
          "5 + 3 should equal 8"
        end
        product = PositiveInt_Impl_.multiply(a, b)
        assert 15 == PositiveInt_Impl_.to_int(product) do
          "5 * 3 should equal 15"
        end
        diff = {:SafeSub, a, b}
        assert match?({:ok, _}, diff) do
          "5 - 3 should succeed"
        end
        case (elem(diff, 0)) do
          0 ->
            g = elem(diff, 1)
            result = g
            assert 2 == PositiveInt_Impl_.to_int(result) do
              "5 - 3 should equal 2"
            end
          1 ->
            g = elem(diff, 1)
            reason = g
            flunk("Subtraction should not fail: " <> reason)
        end
        invalid_diff = {:SafeSub, b, a}
        assert match?({:error, _}, invalid_diff) do
          "3 - 5 should fail (non-positive result)"
        end
      else
        flunk("Valid positive integers should parse")
      end
    else
      flunk("Valid positive integers should parse")
    end
    zero = {:Parse, 0}
    assert match?({:error, _}, zero) do
      "Zero should be rejected"
    end
    negative = {:Parse, -5}
    assert match?({:error, _}, negative) do
      "Negative number should be rejected"
    end
  end
  test "non empty string operations" do
    str = {:Parse, "  hello world  "}
    assert match?({:ok, _}, str) do
      "Non-empty string should parse"
    end
    case (elem(str, 0)) do
      0 ->
        g = elem(str, 1)
        s = g
        trimmed = {:SafeTrim, s}
        assert match?({:ok, _}, trimmed) do
          "Trimming non-empty content should succeed"
        end
        case (elem(trimmed, 0)) do
          0 ->
            g = elem(trimmed, 1)
            trimmed_str = g
            assert "hello world" == NonEmptyString_Impl_.to_string(trimmed_str) do
              "Trim should remove whitespace"
            end
          1 ->
            g = elem(trimmed, 1)
            reason = g
            flunk("Trim should not fail: " <> reason)
        end
        upper = NonEmptyString_Impl_.to_upper_case(s)
        assert "  HELLO WORLD  " == NonEmptyString_Impl_.to_string(upper) do
          "toUpperCase should work"
        end
        lower = NonEmptyString_Impl_.to_lower_case(s)
        assert "  hello world  " == NonEmptyString_Impl_.to_string(lower) do
          "toLowerCase should work"
        end
        assert 15 == NonEmptyString_Impl_.length(s) do
          "Length should be preserved"
        end
      1 ->
        g = elem(str, 1)
        reason = g
        flunk("Valid non-empty string should not fail: " <> reason)
    end
    empty = {:Parse, ""}
    assert match?({:error, _}, empty) do
      "Empty string should be rejected"
    end
    whitespace_only = {:Parse, "   "}
    assert match?({:ok, _}, whitespace_only) do
      "Whitespace-only string should parse"
    end
    case (elem(whitespace_only, 0)) do
      0 ->
        g = elem(whitespace_only, 1)
        ws = g
        trimmed = {:SafeTrim, ws}
        assert match?({:error, _}, trimmed) do
          "Trimming whitespace-only should fail"
        end
      1 ->
        _g = elem(whitespace_only, 1)
        flunk("Whitespace-only should parse")
    end
  end
  test "result chaining" do
    domain_result = {:Filter, {:Map, {:Parse, "test@example.com"}, fn email -> Email_Impl_.get_domain(email) end}, fn domain -> domain == "example.com" end, "Wrong domain"}
    assert match?({:ok, _}, domain_result) do
      "Email domain chain should succeed"
    end
    case (elem(domain_result, 0)) do
      0 ->
        g = elem(domain_result, 1)
        domain = g
        assert "example.com" == domain do
          "Domain should be extracted correctly"
        end
      1 ->
        g = elem(domain_result, 1)
        reason = g
        flunk("Domain extraction should not fail: " <> reason)
    end
    failed_filter = {:Filter, {:Map, {:Parse, "test@wrong.com"}, fn email -> Email_Impl_.get_domain(email) end}, fn domain -> domain == "example.com" end, "Wrong domain"}
    assert match?({:error, _}, failed_filter) do
      "Filter should reject wrong domain"
    end
  end
  test "option conversion" do
    email_result = {:Parse, "user@example.com"}
    email_option = {:ToOption, email_result}
    assert match?({:some, _}, email_option) do
      "Valid email should convert to Some"
    end
    case (elem(email_option, 0)) do
      0 ->
        g = elem(email_option, 1)
        email = g
        assert "example.com" == Email_Impl_.get_domain(email) do
          "Option content should be preserved"
        end
      1 ->
        flunk("Valid email should not be None")
    end
    invalid_email_result = {:Parse, "invalid"}
    invalid_email_option = {:ToOption, invalid_email_result}
    assert invalid_email_option == :none do
      "Invalid email should convert to None"
    end
  end
  test "error handling" do
    invalid_email = {:Parse, "invalid-email"}
    case (elem(invalid_email, 0)) do
      0 ->
        _g = elem(invalid_email, 1)
        flunk("Invalid email should not parse")
      1 ->
        g = elem(invalid_email, 1)
        message = g
        assert message.indexOf("Invalid email") >= 0 do
          "Error message should be descriptive"
        end
    end
    large_int = {:Parse, 1000000}
    assert match?({:ok, _}, large_int) do
      "Large positive integer should parse"
    end
    case (elem(large_int, 0)) do
      0 ->
        g = elem(large_int, 1)
        large = g
        doubled = PositiveInt_Impl_.multiply(large, large)
        assert PositiveInt_Impl_.to_int(doubled) > 0 do
          "Large multiplication should remain positive"
        end
      1 ->
        _g = elem(large_int, 1)
        flunk("Large integer should parse")
    end
  end
  test "real world scenario" do
    user_email = {:Parse, "john.doe@company.com"}
    user_id = {:Parse, "johndoe123"}
    user_age = {:Parse, 25}
    user_name = {:Parse, "John Doe"}
    assert match?({:ok, _}, user_email) do
      "User email should be valid"
    end
    assert match?({:ok, _}, user_id) do
      "User ID should be valid"
    end
    assert match?({:ok, _}, user_age) do
      "User age should be valid"
    end
    assert match?({:ok, _}, user_name) do
      "User name should be valid"
    end
    if (elem(user_email, 0) == 0) do
      g = elem(user_email, 1)
      if (elem(user_id, 0) == 0) do
        g1 = elem(user_id, 1)
        if (elem(user_age, 0) == 0) do
          g2 = elem(user_age, 1)
          if (elem(user_name, 0) == 0) do
            g3 = elem(user_name, 1)
            name = g3
            id = g1
            email = g
            age = g2
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
            assert "john.doe@company.com" == profile_email do
              "Email should be preserved"
            end
            assert "johndoe123" == profile_normalized_id do
              "ID should be normalized"
            end
            assert profile_is_company_email do
              "Company email should be detected"
            end
            assert "John Doe" == profile_display_name do
              "Name should be preserved"
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
    else
      flunk("All user data should be valid")
    end
  end
end