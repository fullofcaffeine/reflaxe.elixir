defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Comprehensive test for Option<T> type compilation
     * Tests idiomatic Haxe patterns compiling to BEAM-friendly Elixir
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_option_construction()

    Main.test_pattern_matching()

    Main.test_functional_operations()

    Main.test_beam_integration()

    Main.test_null_safety()

    Main.test_collection_operations()
  end

  @doc "Generated from Haxe testOptionConstruction"
  def test_option_construction() do
    _some_value = Option.some("hello")

    _none_value = :error

    name = "world"

    nullable_name = nil

    _option_from_value = OptionTools.from_nullable(name)

    _option_from_null = OptionTools.from_nullable(nullable_name)

    _some_person = Option.some("Alice")

    _no_person = :error
  end

  @doc "Generated from Haxe testPatternMatching"
  def test_pattern_matching() do
    temp_string = nil
    temp_number = nil

    user = Option.some("Bob")

    temp_string = nil

    case (case user do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, name} -> g_array = elem(user, 1)
    temp_string = "Hello, " <> name
      1 -> temp_string = "Hello, anonymous"
    end

    scores = Option.some([1, 2, 3])

    temp_number = nil

    case (case scores do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, _score_list} -> g_array = elem(scores, 1)
    temp_number = score_list.length
      1 -> temp_number = 0
    end

    _total = temp_number

    Main.process_user(Option.some("Charlie"))

    Main.process_user(:error)
  end

  @doc "Generated from Haxe processUser"
  def process_user(user) do
    case (case user do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      {0, name} -> g_array = elem(user, 1)
    Log.trace("Processing user: " <> name, %{"fileName" => "Main.hx", "lineNumber" => 68, "className" => "Main", "methodName" => "processUser"})
      1 -> Log.trace("No user to process", %{"fileName" => "Main.hx", "lineNumber" => 69, "className" => "Main", "methodName" => "processUser"})
    end
  end

  @doc "Generated from Haxe testFunctionalOperations"
  def test_functional_operations() do
    temp_result = nil

    user = Option.some("David")

    _upper_name = OptionTools.map(user, fn name -> name.to_upper_case() end)

    _long_name = OptionTools.filter(user, fn name -> (name.length > 3) end)

    _processed_user = OptionTools.then(user, fn name -> if ((name.length > 0)), do: temp_result = Option.some(name <> "!"), else: temp_result = :error
    temp_result end)

    _final_result = OptionTools.then(OptionTools.filter(OptionTools.map(user, fn name -> name.to_upper_case() end), fn name -> (name.length > 2) end), fn name -> Option.some(name <> " [PROCESSED]") end)

    _greeting = OptionTools.unwrap(user, "Anonymous")

    _expensive_default = OptionTools.lazy_unwrap(user, fn  -> "Computed default" end)

    first = Option.some("First")

    second = :error

    _combined = OptionTools.or_(first, second)

    _lazy_second = OptionTools.lazy_or(first, fn  -> Option.some("Lazy second") end)
  end

  @doc "Generated from Haxe testBeamIntegration"
  def test_beam_integration() do
    user = Option.some("Eve")

    _user_result = OptionTools.to_result(user, "User not found")

    ok_result = {:ok, "Frank"}

    error_result = {:error, "Not found"}

    _option_from_ok = OptionTools.from_result(ok_result)

    _option_from_error = OptionTools.from_result(error_result)

    _reply = OptionTools.to_reply(user)

    valid_user = Option.some("Grace")

    _confirmed_user = OptionTools.expect(valid_user, "Expected valid user")
  end

  @doc "Generated from Haxe testNullSafety"
  def test_null_safety() do
    maybe_null = nil

    safe_option = OptionTools.from_nullable(maybe_null)

    _result = OptionTools.unwrap(OptionTools.map(safe_option, fn s -> s.length end), 0)

    _has_value = OptionTools.is_some(safe_option)

    _is_empty = OptionTools.is_none(safe_option)

    _back_to_nullable = OptionTools.to_nullable(safe_option)
  end

  @doc "Generated from Haxe testCollectionOperations"
  def test_collection_operations() do
    temp_array1 = nil
    temp_array = nil

    options = [Option.some(1), :error, Option.some(3), Option.some(4), :error]

    _values = OptionTools.values(options)

    all_options = [Option.some(1), Option.some(2), Option.some(3)]

    _combined = OptionTools.all(all_options)

    mixed_options = [Option.some(1), :error, Option.some(3)]

    _failed_combine = OptionTools.all(mixed_options)

    g_array = []
    g_counter = 0
    Enum.map(options, fn item -> OptionTools.map(item, fn x -> (x * 2) end) end)
    temp_array1 = g_array

    g_array = []
    g_counter = 0
    Enum.filter(temp_array1, fn item -> OptionTools.is_some(item) end)
    temp_array = g_array
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
