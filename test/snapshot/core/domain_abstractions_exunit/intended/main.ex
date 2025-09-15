defmodule Main do
  use ExUnit.Case

  test "email validation" do
    valid_email = Email.parse("user@example.com")
    assert match?({:ok, _}, valid_email)

    case valid_email do
      {:ok, email} ->
        actual = Email.get_domain(email)
        assert actual == "example.com"
        actual = Email.get_local_part(email)
        assert actual == "user"
        condition = Email.has_domain(email, "example.com")
        assert condition
        condition = Email.has_domain(email, "other.com")
        assert not condition
        normalized = Email.normalize(email)
        actual = Email.to_string(normalized)
        assert actual == "user@example.com"
      {:error, reason} ->
        flunk("Valid email should not fail: #{reason}")
    end

    invalid_email = Email.parse("not-an-email")
    assert match?({:error, _}, invalid_email)

    empty_email = Email.parse("")
    assert match?({:error, _}, empty_email)
  end

  test "user id validation" do
    user_id = UserId.parse("User123")
    assert match?({:ok, _}, user_id)

    case user_id do
      {:ok, id} ->
        actual = UserId.to_string(UserId.normalize(id))
        assert actual == "user123"
        condition = UserId.starts_with(id, "User")
        assert condition
        condition = UserId.starts_with_ignore_case(id, "user")
        assert condition
        actual = UserId.length(id)
        assert actual == 7
      {:error, reason} ->
        flunk("Valid user ID should not fail: #{reason}")
    end

    empty_user_id = UserId.parse("")
    assert match?({:error, _}, empty_user_id)

    invalid_user_id = UserId.parse("user@123")
    assert match?({:error, _}, invalid_user_id)
  end

  test "positive int arithmetic" do
    pos1 = PositiveInt.parse(5)
    pos2 = PositiveInt.parse(3)
    assert match?({:ok, _}, pos1)
    assert match?({:ok, _}, pos2)

    with {:ok, a} <- pos1,
         {:ok, b} <- pos2 do
      sum = PositiveInt.add(a, b)
      actual = PositiveInt.to_int(sum)
      assert actual == 8

      product = PositiveInt.multiply(a, b)
      actual = PositiveInt.to_int(product)
      assert actual == 15

      diff = PositiveInt.safe_sub(a, b)
      assert match?({:ok, _}, diff)

      case diff do
        {:ok, result} ->
          actual = PositiveInt.to_int(result)
          assert actual == 2
        {:error, reason} ->
          flunk("Subtraction should not fail: #{reason}")
      end

      invalid_diff = PositiveInt.safe_sub(b, a)
      assert match?({:error, _}, invalid_diff)
    else
      _ -> flunk("Valid positive integers should parse")
    end

    zero = PositiveInt.parse(0)
    assert match?({:error, _}, zero)

    negative = PositiveInt.parse(-5)
    assert match?({:error, _}, negative)
  end

  test "non empty string operations" do
    str = NonEmptyString.parse("  hello world  ")
    assert match?({:ok, _}, str)

    case str do
      {:ok, s} ->
        actual = NonEmptyString.to_string(s)
        assert actual == "  hello world  "

        trimmed = NonEmptyString.safe_trim(s)
        assert match?({:ok, _}, trimmed)

        case trimmed do
          {:ok, t} ->
            actual = NonEmptyString.to_string(t)
            assert actual == "hello world"
          {:error, reason} ->
            flunk("Trim should not fail: #{reason}")
        end

        condition = NonEmptyString.starts_with(s, "  hello")
        assert condition

        condition = NonEmptyString.ends_with(s, "world  ")
        assert condition

        condition = NonEmptyString.contains(s, "lo wo")
        assert condition

        upper = NonEmptyString.to_upper_case(s)
        actual = NonEmptyString.to_string(upper)
        assert actual == "  HELLO WORLD  "
      {:error, reason} ->
        flunk("Valid string should not fail: #{reason}")
    end

    empty_str = NonEmptyString.parse("")
    assert match?({:error, _}, empty_str)

    whitespace_str = NonEmptyString.parse("   ")
    assert match?({:error, _}, whitespace_str)
  end

  test "functional composition" do
    result = NonEmptyString.parse("hello")
      |> ResultTools.map(fn s -> NonEmptyString.to_upper_case(s) end)
      |> ResultTools.flat_map(fn s -> NonEmptyString.safe_replace(s, "HELLO", "WORLD") end)

    assert match?({:ok, _}, result)

    case result do
      {:ok, value} ->
        actual = NonEmptyString.to_string(value)
        assert actual == "WORLD"
      {:error, reason} ->
        flunk("Composition should not fail: #{reason}")
    end

    email_result = Email.parse("USER@EXAMPLE.COM")
      |> ResultTools.map(fn e -> Email.normalize(e) end)
      |> ResultTools.map(fn e -> Email.get_domain(e) end)

    assert match?({:ok, _}, email_result)

    case email_result do
      {:ok, domain} ->
        assert domain == "example.com"
      {:error, reason} ->
        flunk("Email processing should not fail: #{reason}")
    end

    number_result = PositiveInt.parse(10)
      |> ResultTools.flat_map(fn n -> PositiveInt.safe_sub(n, ResultTools.unwrap(PositiveInt.parse(3))) end)
      |> ResultTools.map(fn n -> PositiveInt.multiply(n, ResultTools.unwrap(PositiveInt.parse(2))) end)

    assert match?({:ok, _}, number_result)

    case number_result do
      {:ok, value} ->
        actual = PositiveInt.to_int(value)
        assert actual == 14
      {:error, reason} ->
        flunk("Math composition should not fail: #{reason}")
    end
  end

  test "result tools utilities" do
    ok_result = {:ok, 42}
    error_result = {:error, "something went wrong"}

    assert ResultTools.is_ok(ok_result)
    assert not ResultTools.is_ok(error_result)

    assert ResultTools.is_error(error_result)
    assert not ResultTools.is_error(ok_result)

    value = ResultTools.unwrap(ok_result)
    assert value == 42

    assert_raise(ArgumentError, fn ->
      ResultTools.unwrap(error_result)
    end)

    default_value = ResultTools.unwrap_or(error_result, 0)
    assert default_value == 0

    unwrapped_value = ResultTools.unwrap_or(ok_result, 0)
    assert unwrapped_value == 42

    mapped = ResultTools.map(ok_result, fn x -> x * 2 end)
    assert mapped == {:ok, 84}

    mapped_error = ResultTools.map(error_result, fn x -> x * 2 end)
    assert mapped_error == error_result

    flat_mapped = ResultTools.flat_map(ok_result, fn x -> {:ok, x + 10} end)
    assert flat_mapped == {:ok, 52}

    flat_mapped_error = ResultTools.flat_map(ok_result, fn _ -> {:error, "failed"} end)
    assert flat_mapped_error == {:error, "failed"}

    filtered = ResultTools.filter(ok_result, fn x -> x > 40 end, "too small")
    assert filtered == ok_result

    filtered_fail = ResultTools.filter(ok_result, fn x -> x > 50 end, "too small")
    assert filtered_fail == {:error, "too small"}
  end
end