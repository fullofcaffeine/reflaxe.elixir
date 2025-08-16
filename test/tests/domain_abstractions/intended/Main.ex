defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Comprehensive test for type-safe domain abstractions.
 * 
 * This test demonstrates the four domain abstractions inspired by 
 * Domain-Driven Design and Gleam's type philosophy:
 * - Email: Type-safe email validation with domain extraction
 * - UserId: Alphanumeric user identifiers with case handling
 * - PositiveInt: Integers guaranteed to be > 0 with safe arithmetic
 * - NonEmptyString: Strings guaranteed to have content with safe operations
 * 
 * All abstractions follow "Parse, Don't Validate" principle and provide
 * runtime validation with minimal performance impact.
 
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("Testing domain abstractions with type safety...", %{"fileName" => "Main.hx", "lineNumber" => 27, "className" => "Main", "methodName" => "main"})
    Main.testEmailValidation()
    Main.testUserIdValidation()
    Main.testPositiveIntArithmetic()
    Main.testNonEmptyStringOperations()
    Main.testFunctionalComposition()
    Main.testErrorHandling()
    Main.testRealWorldScenarios()
    Log.trace("Domain abstraction tests completed!", %{"fileName" => "Main.hx", "lineNumber" => 37, "className" => "Main", "methodName" => "main"})
  end

  @doc """
    Test Email domain abstraction with validation and extraction

  """
  @spec test_email_validation() :: nil
  def test_email_validation() do
    Log.trace("=== Email Validation Tests ===", %{"fileName" => "Main.hx", "lineNumber" => 44, "className" => "Main", "methodName" => "testEmailValidation"})
    email_result = Email_Impl_.parse("user@example.com")
    case (case email_result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case email_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        email = _g
        domain = Email_Impl_.getDomain(email)
        local_part = Email_Impl_.getLocalPart(email)
        Log.trace("Valid email - Domain: " <> domain <> ", Local: " <> local_part, %{"fileName" => "Main.hx", "lineNumber" => 52, "className" => "Main", "methodName" => "testEmailValidation"})
        is_example_domain = Email_Impl_.hasDomain(email, "example.com")
        Log.trace("Is example.com domain: " <> Std.string(is_example_domain), %{"fileName" => "Main.hx", "lineNumber" => 56, "className" => "Main", "methodName" => "testEmailValidation"})
        normalized = Email_Impl_.normalize(email)
        Log.trace("Normalized: " <> Email_Impl_.toString(normalized), %{"fileName" => "Main.hx", "lineNumber" => 60, "className" => "Main", "methodName" => "testEmailValidation"})
      1 ->
        _g = case email_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Unexpected email validation failure: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 63, "className" => "Main", "methodName" => "testEmailValidation"})
    end
    invalid_emails = ["invalid-email", "@example.com", "user@", "user@@example.com", "", "user space@example.com"]
    _g = 0
    Enum.map(invalid_emails, fn item -> invalid_email = Enum.at(invalid_emails, _g)
    _g = _g + 1
    _g = Email_Impl_.parse(invalid_email)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        Log.trace("ERROR: Invalid email \"" <> invalid_email <> "\" was accepted", %{"fileName" => "Main.hx", "lineNumber" => 79, "className" => "Main", "methodName" => "testEmailValidation"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Correctly rejected \"" <> invalid_email <> "\": " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 81, "className" => "Main", "methodName" => "testEmailValidation"})
    end end)
    email1_result = Email_Impl_.parse("Test@Example.Com")
    email2_result = Email_Impl_.parse("test@example.com")
    if (ResultTools.isOk(email1_result) && ResultTools.isOk(email2_result)) do
      email1 = ResultTools.unwrap(email1_result)
      email2 = ResultTools.unwrap(email2_result)
      are_equal = Email_Impl_.equals(email1, email2)
      Log.trace("Case-insensitive equality: " <> Std.string(are_equal), %{"fileName" => "Main.hx", "lineNumber" => 93, "className" => "Main", "methodName" => "testEmailValidation"})
    end
  end

  @doc """
    Test UserId domain abstraction with alphanumeric validation

  """
  @spec test_user_id_validation() :: nil
  def test_user_id_validation() do
    Log.trace("=== UserId Validation Tests ===", %{"fileName" => "Main.hx", "lineNumber" => 101, "className" => "Main", "methodName" => "testUserIdValidation"})
    valid_ids = ["user123", "Alice", "Bob42", "testUser"]
    _g = 0
    Enum.map(valid_ids, fn item -> valid_id = Enum.at(valid_ids, _g)
    _g = _g + 1
    _g = UserId_Impl_.parse(valid_id)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        user_id = _g
        length = length(UserId_Impl_)
        normalized = UserId_Impl_.normalize(user_id)
        Log.trace("Valid UserId \"" <> valid_id <> "\" - Length: " <> Integer.to_string(length) <> ", Normalized: " <> UserId_Impl_.toString(normalized), %{"fileName" => "Main.hx", "lineNumber" => 111, "className" => "Main", "methodName" => "testUserIdValidation"})
        starts_with_user = UserId_Impl_.startsWithIgnoreCase(user_id, "user")
        Log.trace("Starts with \"user\" (case-insensitive): " <> Std.string(starts_with_user), %{"fileName" => "Main.hx", "lineNumber" => 115, "className" => "Main", "methodName" => "testUserIdValidation"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Unexpected UserId validation failure for \"" <> valid_id <> "\": " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 118, "className" => "Main", "methodName" => "testUserIdValidation"})
    end end)
    temp_array = nil
    _g = []
    _g = 0
    (
      try do
        loop_fn = fn ->
          if (_g < 60) do
            try do
              _g = _g + 1
    _g ++ ["a"]
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
    temp_array = _g
    invalid_ids = ["ab", "user@123", "user 123", "user-123", "", Enum.join((temp_array), "")]
    _g = 0
    Enum.map(invalid_ids, fn item -> invalid_id = Enum.at(invalid_ids, _g)
    _g = _g + 1
    _g = UserId_Impl_.parse(invalid_id)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        Log.trace("ERROR: Invalid UserId \"" <> invalid_id <> "\" was accepted", %{"fileName" => "Main.hx", "lineNumber" => 135, "className" => "Main", "methodName" => "testUserIdValidation"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Correctly rejected \"" <> invalid_id <> "\": " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 137, "className" => "Main", "methodName" => "testUserIdValidation"})
    end end)
    id1_result = UserId_Impl_.parse("User123")
    id2_result = UserId_Impl_.parse("user123")
    if (ResultTools.isOk(id1_result) && ResultTools.isOk(id2_result)) do
      id1 = ResultTools.unwrap(id1_result)
      id2 = ResultTools.unwrap(id2_result)
      exact_equal = UserId_Impl_.equals(id1, id2)
      case_insensitive_equal = UserId_Impl_.equalsIgnoreCase(id1, id2)
      Log.trace("Exact equality: " <> Std.string(exact_equal) <> ", Case-insensitive: " <> Std.string(case_insensitive_equal), %{"fileName" => "Main.hx", "lineNumber" => 150, "className" => "Main", "methodName" => "testUserIdValidation"})
    end
  end

  @doc """
    Test PositiveInt domain abstraction with safe arithmetic

  """
  @spec test_positive_int_arithmetic() :: nil
  def test_positive_int_arithmetic() do
    Log.trace("=== PositiveInt Arithmetic Tests ===", %{"fileName" => "Main.hx", "lineNumber" => 158, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
    valid_numbers = [1, 5, 42, 100, 999]
    _g = 0
    Enum.map(valid_numbers, fn item -> valid_num = Enum.at(valid_numbers, _g)
    _g = _g + 1
    _g = PositiveInt_Impl_.parse(valid_num)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        pos_int = _g
        Log.trace("Valid PositiveInt: " <> PositiveInt_Impl_.toString(pos_int), %{"fileName" => "Main.hx", "lineNumber" => 166, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
        doubled = PositiveInt_Impl_.multiply(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(2)))
        added = PositiveInt_Impl_.add(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(10)))
        Log.trace("Doubled: " <> PositiveInt_Impl_.toString(doubled) <> ", Added 10: " <> PositiveInt_Impl_.toString(added), %{"fileName" => "Main.hx", "lineNumber" => 171, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
        subtract_result = PositiveInt_Impl_.safeSub(pos_int, ResultTools.unwrap(PositiveInt_Impl_.parse(1)))
        case (case subtract_result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            _g = case subtract_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            result = _g
            Log.trace("Safe subtraction result: " <> PositiveInt_Impl_.toString(result), %{"fileName" => "Main.hx", "lineNumber" => 177, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
          1 ->
            _g = case subtract_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = _g
            Log.trace("Safe subtraction failed: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 179, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
        end
        five = ResultTools.unwrap(PositiveInt_Impl_.parse(5))
        is_greater = PositiveInt_Impl_.greaterThan(pos_int, five)
        min = PositiveInt_Impl_.min(pos_int, five)
        max = PositiveInt_Impl_.max(pos_int, five)
        Log.trace("Greater than 5: " <> Std.string(is_greater) <> ", Min with 5: " <> PositiveInt_Impl_.toString(min) <> ", Max with 5: " <> PositiveInt_Impl_.toString(max), %{"fileName" => "Main.hx", "lineNumber" => 187, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Unexpected PositiveInt validation failure for " <> Integer.to_string(valid_num) <> ": " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 190, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
    end end)
    invalid_numbers = [0, -1, -42, -100]
    _g = 0
    Enum.map(invalid_numbers, fn item -> invalid_num = Enum.at(invalid_numbers, _g)
    _g = _g + 1
    _g = PositiveInt_Impl_.parse(invalid_num)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        Log.trace("ERROR: Invalid PositiveInt " <> Integer.to_string(invalid_num) <> " was accepted", %{"fileName" => "Main.hx", "lineNumber" => 200, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Correctly rejected " <> Integer.to_string(invalid_num) <> ": " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 202, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
    end end)
    five = ResultTools.unwrap(PositiveInt_Impl_.parse(5))
    ten = ResultTools.unwrap(PositiveInt_Impl_.parse(10))
    _g = PositiveInt_Impl_.safeSub(five, ten)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        Log.trace("ERROR: Subtraction that should fail succeeded", %{"fileName" => "Main.hx", "lineNumber" => 213, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Correctly prevented invalid subtraction: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 215, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
    end
    twenty = ResultTools.unwrap(PositiveInt_Impl_.parse(20))
    four = ResultTools.unwrap(PositiveInt_Impl_.parse(4))
    three = ResultTools.unwrap(PositiveInt_Impl_.parse(3))
    _g = PositiveInt_Impl_.safeDiv(twenty, four)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        result = _g
        Log.trace("20 / 4 = " <> PositiveInt_Impl_.toString(result), %{"fileName" => "Main.hx", "lineNumber" => 225, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Division failed: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 227, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
    end
    _g = PositiveInt_Impl_.safeDiv(twenty, three)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        result = _g
        Log.trace("20 / 3 = " <> PositiveInt_Impl_.toString(result) <> " (unexpected success)", %{"fileName" => "Main.hx", "lineNumber" => 232, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("20 / 3 correctly failed (not exact): " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 234, "className" => "Main", "methodName" => "testPositiveIntArithmetic"})
    end
  end

  @doc """
    Test NonEmptyString domain abstraction with safe operations

  """
  @spec test_non_empty_string_operations() :: nil
  def test_non_empty_string_operations() do
    Log.trace("=== NonEmptyString Operations Tests ===", %{"fileName" => "Main.hx", "lineNumber" => 242, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
    valid_strings = ["hello", "world", "test", "NonEmptyString"]
    _g = 0
    Enum.map(valid_strings, fn item -> valid_str = Enum.at(valid_strings, _g)
    _g = _g + 1
    _g = NonEmptyString_Impl_.parse(valid_str)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        non_empty_str = _g
        length = length(NonEmptyString_Impl_)
        upper = NonEmptyString_Impl_.toUpperCase(non_empty_str)
        lower = NonEmptyString_Impl_.toLowerCase(non_empty_str)
        Log.trace("Valid NonEmptyString \"" <> valid_str <> "\" - Length: " <> Integer.to_string(length) <> ", Upper: " <> NonEmptyString_Impl_.toString(upper) <> ", Lower: " <> NonEmptyString_Impl_.toString(lower), %{"fileName" => "Main.hx", "lineNumber" => 253, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
        other = ResultTools.unwrap(NonEmptyString_Impl_.parse("!"))
        concatenated = NonEmptyString_Impl_ ++ non_empty_str
        Log.trace("Concatenated with \"!\": " <> NonEmptyString_Impl_.toString(concatenated), %{"fileName" => "Main.hx", "lineNumber" => 258, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
        first_char = NonEmptyString_Impl_.firstChar(non_empty_str)
        last_char = NonEmptyString_Impl_.lastChar(non_empty_str)
        Log.trace("First char: " <> NonEmptyString_Impl_.toString(first_char) <> ", Last char: " <> NonEmptyString_Impl_.toString(last_char), %{"fileName" => "Main.hx", "lineNumber" => 263, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
        _g = NonEmptyString_Impl_.safeSubstring(non_empty_str, 1)
        case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
          0 ->
            _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            substr = _g
            Log.trace("Substring from index 1: " <> NonEmptyString_Impl_.toString(substr), %{"fileName" => "Main.hx", "lineNumber" => 268, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
          1 ->
            _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
            reason = _g
            Log.trace("Substring failed: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 270, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
        end
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Unexpected NonEmptyString validation failure for \"" <> valid_str <> "\": " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 274, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
    end end)
    invalid_strings = ["", "   ", "\t\n"]
    _g = 0
    Enum.map(invalid_strings, fn item -> invalid_str = Enum.at(invalid_strings, _g)
    _g = _g + 1
    _g = NonEmptyString_Impl_.parse(invalid_str)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        Log.trace("ERROR: Invalid NonEmptyString \"" <> invalid_str <> "\" was accepted", %{"fileName" => "Main.hx", "lineNumber" => 284, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Correctly rejected \"" <> invalid_str <> "\": " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 286, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
    end end)
    whitespace_strings = ["  hello  ", "\tworld\n", "  test  "]
    _g = 0
    Enum.map(whitespace_strings, fn item -> whitespace_str = Enum.at(whitespace_strings, _g)
    _g = _g + 1
    _g = NonEmptyString_Impl_.parseAndTrim(whitespace_str)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        trimmed = _g
        Log.trace("Trimmed \"" <> whitespace_str <> "\" to \"" <> NonEmptyString_Impl_.toString(trimmed) <> "\"", %{"fileName" => "Main.hx", "lineNumber" => 296, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Trim and parse failed for \"" <> whitespace_str <> "\": " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 298, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
    end end)
    test_str = ResultTools.unwrap(NonEmptyString_Impl_.parse("Hello World"))
    starts_with_hello = NonEmptyString_Impl_.startsWith(test_str, "Hello")
    ends_with_world = NonEmptyString_Impl_.endsWith(test_str, "World")
    contains_space = Enum.member?(NonEmptyString_Impl_, test_str)
    Log.trace("String operations - Starts with \"Hello\": " <> Std.string(starts_with_hello) <> ", Ends with \"World\": " <> Std.string(ends_with_world) <> ", Contains space: " <> Std.string(contains_space), %{"fileName" => "Main.hx", "lineNumber" => 307, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
    _g = NonEmptyString_Impl_.safeReplace(test_str, "World", "Universe")
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        replaced = _g
        Log.trace("Replaced \"World\" with \"Universe\": " <> NonEmptyString_Impl_.toString(replaced), %{"fileName" => "Main.hx", "lineNumber" => 312, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Replacement failed: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 314, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
    end
    parts = NonEmptyString_Impl_.splitNonEmpty(test_str, " ")
    Log.trace("Split by space: " <> Integer.to_string(length(parts)) <> " parts", %{"fileName" => "Main.hx", "lineNumber" => 319, "className" => "Main", "methodName" => "testNonEmptyStringOperations"})
    _g = 0
    Enum.map(parts, fn item -> part = Enum.at(parts, _g)
    _g = _g + 1
    Log.trace("  Part: " <> NonEmptyString_Impl_.toString(part), %{"fileName" => "Main.hx", "lineNumber" => 321, "className" => "Main", "methodName" => "testNonEmptyStringOperations"}) end)
  end

  @doc """
    Test functional composition with domain abstractions

  """
  @spec test_functional_composition() :: nil
  def test_functional_composition() do
    Log.trace("=== Functional Composition Tests ===", %{"fileName" => "Main.hx", "lineNumber" => 329, "className" => "Main", "methodName" => "testFunctionalComposition"})
    email_chain = ResultTools.unwrapOr(ResultTools.map(ResultTools.map(Email_Impl_.parse("USER@EXAMPLE.COM"), fn email -> Email_Impl_.normalize(email) end), fn email -> Email_Impl_.getDomain(email) end), "unknown")
    Log.trace("Email chain result: " <> email_chain, %{"fileName" => "Main.hx", "lineNumber" => 336, "className" => "Main", "methodName" => "testFunctionalComposition"})
    user_id_chain = ResultTools.unwrapOr(ResultTools.filter(ResultTools.map(UserId_Impl_.parse("TestUser123"), fn user_id -> UserId_Impl_.normalize(user_id) end), fn user_id -> UserId_Impl_.startsWith(user_id, "test") end, "UserId does not start with 'test'"), ResultTools.unwrap(UserId_Impl_.parse("defaultuser")))
    Log.trace("UserId chain result: " <> UserId_Impl_.toString(user_id_chain), %{"fileName" => "Main.hx", "lineNumber" => 343, "className" => "Main", "methodName" => "testFunctionalComposition"})
    math_chain = ResultTools.unwrapOr(ResultTools.map(ResultTools.flatMap(PositiveInt_Impl_.parse(10), fn n -> PositiveInt_Impl_.safeSub(n, ResultTools.unwrap(PositiveInt_Impl_.parse(3))) end), fn n -> PositiveInt_Impl_.multiply(n, ResultTools.unwrap(PositiveInt_Impl_.parse(2))) end), ResultTools.unwrap(PositiveInt_Impl_.parse(1)))
    Log.trace("Math chain result: " <> PositiveInt_Impl_.toString(math_chain), %{"fileName" => "Main.hx", "lineNumber" => 350, "className" => "Main", "methodName" => "testFunctionalComposition"})
    string_chain = ResultTools.unwrapOr(ResultTools.flatMap(ResultTools.map(ResultTools.flatMap(NonEmptyString_Impl_.parseAndTrim("  hello world  "), fn s -> NonEmptyString_Impl_.safeTrim(s) end), fn s -> NonEmptyString_Impl_.toUpperCase(s) end), fn s -> NonEmptyString_Impl_.safeReplace(s, "WORLD", "UNIVERSE") end), ResultTools.unwrap(NonEmptyString_Impl_.parse("fallback")))
    Log.trace("String chain result: " <> NonEmptyString_Impl_.toString(string_chain), %{"fileName" => "Main.hx", "lineNumber" => 358, "className" => "Main", "methodName" => "testFunctionalComposition"})
    composition_result = Main.buildUserProfile("user123", "  alice@example.com  ", "5")
    case (case composition_result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case composition_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        profile = _g
        Log.trace("User profile created successfully:", %{"fileName" => "Main.hx", "lineNumber" => 364, "className" => "Main", "methodName" => "testFunctionalComposition"})
        Log.trace("  UserId: " <> UserId_Impl_.toString(profile.user_id), %{"fileName" => "Main.hx", "lineNumber" => 365, "className" => "Main", "methodName" => "testFunctionalComposition"})
        Log.trace("  Email: " <> Email_Impl_.toString(profile.email), %{"fileName" => "Main.hx", "lineNumber" => 366, "className" => "Main", "methodName" => "testFunctionalComposition"})
        Log.trace("  Score: " <> PositiveInt_Impl_.toString(profile.score), %{"fileName" => "Main.hx", "lineNumber" => 367, "className" => "Main", "methodName" => "testFunctionalComposition"})
      1 ->
        _g = case composition_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("User profile creation failed: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 369, "className" => "Main", "methodName" => "testFunctionalComposition"})
    end
  end

  @doc """
    Test comprehensive error handling scenarios

  """
  @spec test_error_handling() :: nil
  def test_error_handling() do
    Log.trace("=== Error Handling Tests ===", %{"fileName" => "Main.hx", "lineNumber" => 377, "className" => "Main", "methodName" => "testErrorHandling"})
    invalid_inputs = [%{"email" => "invalid-email", "userId" => "ab", "score" => "0"}, %{"email" => "user@domain", "userId" => "user@123", "score" => "-5"}, %{"email" => "", "userId" => "", "score" => "not-a-number"}]
    _g = 0
    Enum.map(invalid_inputs, fn item -> input = Enum.at(invalid_inputs, _g)
    _g = _g + 1
    _g = Main.buildUserProfile(input.user_id, input.email, input.score)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        Log.trace("ERROR: Invalid input was accepted", %{"fileName" => "Main.hx", "lineNumber" => 389, "className" => "Main", "methodName" => "testErrorHandling"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Correctly rejected invalid input: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 391, "className" => "Main", "methodName" => "testErrorHandling"})
    end end)
    Log.trace("Testing edge cases that should succeed:", %{"fileName" => "Main.hx", "lineNumber" => 396, "className" => "Main", "methodName" => "testErrorHandling"})
    edge_cases = [%{"email" => "a@b.co", "userId" => "usr", "score" => "1"}, %{"email" => "very.long.email.address@very.long.domain.name.example.com", "userId" => "user123456789", "score" => "999"}]
    _g = 0
    Enum.map(edge_cases, fn item -> edge_case = Enum.at(edge_cases, _g)
    _g = _g + 1
    _g = Main.buildUserProfile(edge_case.user_id, edge_case.email, edge_case.score)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        profile = _g
        Log.trace("Edge case succeeded: UserId " <> UserId_Impl_.toString(profile.user_id) <> ", Email " <> Email_Impl_.getDomain(profile.email), %{"fileName" => "Main.hx", "lineNumber" => 406, "className" => "Main", "methodName" => "testErrorHandling"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Edge case failed: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 408, "className" => "Main", "methodName" => "testErrorHandling"})
    end end)
  end

  @doc """
    Test real-world usage scenarios combining multiple abstractions

  """
  @spec test_real_world_scenarios() :: nil
  def test_real_world_scenarios() do
    Log.trace("=== Real-World Scenarios ===", %{"fileName" => "Main.hx", "lineNumber" => 417, "className" => "Main", "methodName" => "testRealWorldScenarios"})
    registration_data = [%{"userId" => "alice123", "email" => "alice@example.com", "preferredName" => "Alice Smith"}, %{"userId" => "bob456", "email" => "bob.jones@company.org", "preferredName" => "Bob"}, %{"userId" => "charlie", "email" => "charlie@test.dev", "preferredName" => "Charlie Brown"}]
    valid_users = []
    _g = 0
    Enum.map(registration_data, fn item -> user_data = Enum.at(registration_data, _g)
    _g = _g + 1
    user_result = Main.createUser(user_data.user_id, user_data.email, user_data.preferred_name)
    case (case user_result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case user_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        user = _g
        valid_users ++ [user]
        Log.trace("User created: " <> NonEmptyString_Impl_.toString(user.display_name) <> " (" <> Email_Impl_.toString(user.email) <> ")", %{"fileName" => "Main.hx", "lineNumber" => 433, "className" => "Main", "methodName" => "testRealWorldScenarios"})
      1 ->
        _g = case user_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("User creation failed: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 435, "className" => "Main", "methodName" => "testRealWorldScenarios"})
    end end)
    Log.trace("Successfully created " <> Integer.to_string(length(valid_users)) <> " users", %{"fileName" => "Main.hx", "lineNumber" => 439, "className" => "Main", "methodName" => "testRealWorldScenarios"})
    config_data = [%{"timeout" => "30", "retries" => "3", "name" => "production"}, %{"timeout" => "0", "retries" => "5", "name" => ""}, %{"timeout" => "60", "retries" => "-1", "name" => "test"}]
    _g = 0
    Enum.map(config_data, fn item -> config = Enum.at(config_data, _g)
    _g = _g + 1
    config_result = Main.validateConfiguration(config.timeout, config.retries, config.name)
    case (case config_result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case config_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        valid_config = _g
        Log.trace("Config valid: " <> NonEmptyString_Impl_.toString(valid_config.name) <> ", timeout: " <> PositiveInt_Impl_.toString(valid_config.timeout) <> "s, retries: " <> PositiveInt_Impl_.toString(valid_config.retries), %{"fileName" => "Main.hx", "lineNumber" => 452, "className" => "Main", "methodName" => "testRealWorldScenarios"})
      1 ->
        _g = case config_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
        reason = _g
        Log.trace("Config invalid: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 454, "className" => "Main", "methodName" => "testRealWorldScenarios"})
    end end)
  end

  @doc """
    Helper function to build user profile combining multiple domain abstractions

  """
  @spec build_user_profile(String.t(), String.t(), String.t()) :: Result.t()
  def build_user_profile(user_id_str, email_str, score_str) do
    ResultTools.flatMap(ResultTools.mapError(UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), fn user_id -> ResultTools.flatMap(ResultTools.mapError(Email_Impl_.parse(StringTools.trim(email_str)), fn e -> "Invalid Email: " <> e end), fn email -> temp_result = nil
    score_int = Std.parseInt(score_str)
    if (score_int == nil), do: {:error, "Invalid score: " <> score_str}, else: nil
    ResultTools.map(ResultTools.mapError(PositiveInt_Impl_.parse(score_int), fn e -> "Invalid score: " <> e end), fn score -> %{"userId" => user_id, "email" => email, "score" => score} end)
    temp_result end) end)
  end

  @doc """
    Helper function to create a user with validation

  """
  @spec create_user(String.t(), String.t(), String.t()) :: Result.t()
  def create_user(user_id_str, email_str, name_str) do
    ResultTools.flatMap(ResultTools.mapError(UserId_Impl_.parse(user_id_str), fn e -> "Invalid UserId: " <> e end), fn user_id -> ResultTools.flatMap(ResultTools.mapError(Email_Impl_.parse(email_str), fn e -> "Invalid Email: " <> e end), fn email -> ResultTools.map(ResultTools.mapError(NonEmptyString_Impl_.parseAndTrim(name_str), fn e -> "Invalid Name: " <> e end), fn display_name -> %{"userId" => user_id, "email" => email, "displayName" => display_name} end) end) end)
  end

  @doc """
    Helper function to validate configuration with multiple constraints

  """
  @spec validate_configuration(String.t(), String.t(), String.t()) :: Result.t()
  def validate_configuration(timeout_str, retries_str, name_str) do
    timeout_int = Std.parseInt(timeout_str)
    retries_int = Std.parseInt(retries_str)
    if (timeout_int == nil), do: {:error, "Timeout must be a number: " <> timeout_str}, else: nil
    if (retries_int == nil), do: {:error, "Retries must be a number: " <> retries_str}, else: nil
    ResultTools.flatMap(ResultTools.mapError(PositiveInt_Impl_.parse(timeout_int), fn e -> "Invalid timeout: " <> e end), fn timeout -> ResultTools.flatMap(ResultTools.mapError(PositiveInt_Impl_.parse(retries_int), fn e -> "Invalid retries: " <> e end), fn retries -> ResultTools.map(ResultTools.mapError(NonEmptyString_Impl_.parseAndTrim(name_str), fn e -> "Invalid name: " <> e end), fn name -> %{"timeout" => timeout, "retries" => retries, "name" => name} end) end) end)
  end

end
