defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Comprehensive test for Option<T> type compilation
 * Tests idiomatic Haxe patterns compiling to BEAM-friendly Elixir
 
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Main.testOptionConstruction()
    Main.testPatternMatching()
    Main.testFunctionalOperations()
    Main.testBeamIntegration()
    Main.testNullSafety()
    Main.testCollectionOperations()
  end

  @doc """
    Test basic Option construction patterns

  """
  @spec test_option_construction() :: nil
  def test_option_construction() do
    {:some, "hello"}
    :none
    name = "world"
    nullable_name = nil
    OptionTools.fromNullable(name)
    OptionTools.fromNullable(nullable_name)
    {:some, "Alice"}
    :none
  end

  @doc """
    Test idiomatic Haxe pattern matching

  """
  @spec test_pattern_matching() :: nil
  def test_pattern_matching() do
    user = {:some, "Bob"}
    temp_string = nil
    case (case user do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case user do {:some, value} -> value; :none -> nil; _ -> nil end
        name = _g
        temp_string = "Hello, " <> name
      1 ->
        temp_string = "Hello, anonymous"
    end
    scores = {:some, [1, 2, 3]}
    temp_number = nil
    case (case scores do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case scores do {:some, value} -> value; :none -> nil; _ -> nil end
        score_list = _g
        temp_number = length(score_list)
      1 ->
        temp_number = 0
    end
    temp_number
    Main.processUser({:some, "Charlie"})
    Main.processUser(:none)
  end

  @doc "Function process_user"
  @spec process_user(Option.t()) :: nil
  def process_user(user) do
    case (case user do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case user do {:some, value} -> value; :none -> nil; _ -> nil end
        name = _g
        Log.trace("Processing user: " <> name, %{"fileName" => "Main.hx", "lineNumber" => 68, "className" => "Main", "methodName" => "processUser"})
      1 ->
        Log.trace("No user to process", %{"fileName" => "Main.hx", "lineNumber" => 69, "className" => "Main", "methodName" => "processUser"})
    end
  end

  @doc """
    Test functional operations (map, filter, flatMap, etc.)

  """
  @spec test_functional_operations() :: nil
  def test_functional_operations() do
    user = {:some, "David"}
    OptionTools.map(user, fn name -> String.upcase(name) end)
    OptionTools.filter(user, fn name -> String.length(name) > 3 end)
    OptionTools.then(user, fn name -> temp_result = nil
    if (String.length(name) > 0), do: temp_result = {:some, name <> "!"}, else: temp_result = :none
    temp_result end)
    OptionTools.then(OptionTools.filter(OptionTools.map(user, fn name -> String.upcase(name) end), fn name -> String.length(name) > 2 end), fn name -> {:some, name <> " [PROCESSED]"} end)
    OptionTools.unwrap(user, "Anonymous")
    OptionTools.lazyUnwrap(user, fn  -> "Computed default" end)
    first = {:some, "First"}
    second = :none
    OptionTools.or(first, second)
    OptionTools.lazyOr(first, fn  -> {:some, "Lazy second"} end)
  end

  @doc """
    Test BEAM/OTP integration patterns

  """
  @spec test_beam_integration() :: nil
  def test_beam_integration() do
    user = {:some, "Eve"}
    OptionTools.toResult(user, "User not found")
    ok_result = {:ok, "Frank"}
    error_result = {:error, "Not found"}
    OptionTools.fromResult(ok_result)
    OptionTools.fromResult(error_result)
    OptionTools.toReply(user)
    valid_user = {:some, "Grace"}
    OptionTools.expect(valid_user, "Expected valid user")
  end

  @doc """
    Test null safety guarantees

  """
  @spec test_null_safety() :: nil
  def test_null_safety() do
    maybe_null = nil
    safe_option = OptionTools.fromNullable(maybe_null)
    OptionTools.unwrap(OptionTools.map(safe_option, fn s -> String.length(s) end), 0)
    OptionTools.isSome(safe_option)
    OptionTools.isNone(safe_option)
    OptionTools.toNullable(safe_option)
  end

  @doc """
    Test collection operations with Option

  """
  @spec test_collection_operations() :: nil
  def test_collection_operations() do
    options = [{:some, 1}, :none, {:some, 3}, {:some, 4}, :none]
    OptionTools.values(options)
    all_options = [{:some, 1}, {:some, 2}, {:some, 3}]
    OptionTools.all(all_options)
    mixed_options = [{:some, 1}, :none, {:some, 3}]
    OptionTools.all(mixed_options)
    temp_array = nil
    temp_array1 = nil
    _g = []
    _g = 0
    Enum.map(options, fn item -> v = Enum.at(options, _g)
    _g = _g + 1
    _g ++ [OptionTools.map(v, fn x -> x * 2 end)] end)
    temp_array1 = _g
    _g = []
    _g = 0
    Enum.filter(temp_array1, fn item -> (OptionTools.isSome(item)) end)
    temp_array = _g
  end

end


defmodule UserService do
  @moduledoc """
  UserService module generated from Haxe
  
  
 * Example service class showing Option usage patterns
 
  """

  # Static functions
  @doc "Function find_user"
  @spec find_user(String.t()) :: Option.t()
  def find_user(name) do
    _g = 0
    _g = UserService.users
    Enum.find(_g, fn item -> (user.name == name) end)
    :none
  end

  @doc "Function get_user_email"
  @spec get_user_email(String.t()) :: Option.t()
  def get_user_email(name) do
    OptionTools.then(UserService.findUser(name), fn user -> user.email end)
  end

  @doc "Function notify_user"
  @spec notify_user(String.t(), String.t()) :: boolean()
  def notify_user(name, message) do
    OptionTools.unwrap(OptionTools.map(UserService.getUserEmail(name), fn email -> UserService.sendEmail(email, message) end), false)
  end

  @doc "Function send_email"
  @spec send_email(String.t(), String.t()) :: boolean()
  def send_email(email, message) do
    Log.trace("Sending email to " <> email <> ": " <> message, %{"fileName" => "Main.hx", "lineNumber" => 225, "className" => "UserService", "methodName" => "sendEmail"})
    true
  end

end
