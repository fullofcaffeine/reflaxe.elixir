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
    Main.test_option_construction()
    Main.test_pattern_matching()
    Main.test_functional_operations()
    Main.test_beam_integration()
    Main.test_null_safety()
    Main.test_collection_operations()
  end

  @doc """
    Test basic Option construction patterns

  """
  @spec test_option_construction() :: nil
  def test_option_construction() do
    {:ok, "hello"}
    :error
    name = "world"
    nullable_name = nil
    OptionTools.from_nullable(name)
    OptionTools.from_nullable(nullable_name)
    {:ok, "Alice"}
    :error
  end

  @doc """
    Test idiomatic Haxe pattern matching

  """
  @spec test_pattern_matching() :: nil
  def test_pattern_matching() do
    user = {:ok, "Bob"}
    temp_string = nil
    case (case user do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 ->
        g = case user do {:ok, value} -> value; :error -> nil; _ -> nil end
        name = g
        temp_string = "Hello, " <> name
      1 ->
        temp_string = "Hello, anonymous"
    end
    scores = {:ok, [1, 2, 3]}
    temp_number = nil
    case (case scores do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 ->
        g = case scores do {:ok, value} -> value; :error -> nil; _ -> nil end
        score_list = g
        temp_number = score_list.length
      1 ->
        temp_number = 0
    end
    temp_number
    Main.process_user({:ok, "Charlie"})
    Main.process_user(:error)
  end

  @doc "Function process_user"
  @spec process_user(Option.t()) :: nil
  def process_user(user) do
    case (case user do {:ok, _} -> 0; :error -> 1; _ -> -1 end) do
      0 ->
        g = case user do {:ok, value} -> value; :error -> nil; _ -> nil end
        name = g
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
    user = {:ok, "David"}
    OptionTools.map(user, fn name -> name.to_upper_case() end)
    OptionTools.filter(user, fn name -> name.length > 3 end)
    OptionTools.then(user, fn name -> temp_result = nil
    temp_result = if (name.length > 0), do: {:ok, name <> "!"}, else: :error
    temp_result end)
    OptionTools.then(OptionTools.filter(OptionTools.map(user, fn name -> name.to_upper_case() end), fn name -> name.length > 2 end), fn name -> {:ok, name <> " [PROCESSED]"} end)
    OptionTools.unwrap(user, "Anonymous")
    OptionTools.lazy_unwrap(user, fn  -> "Computed default" end)
    first = {:ok, "First"}
    second = :error
    OptionTools.or_(first, second)
    OptionTools.lazy_or(first, fn  -> {:ok, "Lazy second"} end)
  end

  @doc """
    Test BEAM/OTP integration patterns

  """
  @spec test_beam_integration() :: nil
  def test_beam_integration() do
    user = {:ok, "Eve"}
    OptionTools.to_result(user, "User not found")
    ok_result = {:ok, "Frank"}
    error_result = {:error, "Not found"}
    OptionTools.from_result(ok_result)
    OptionTools.from_result(error_result)
    OptionTools.to_reply(user)
    valid_user = {:ok, "Grace"}
    OptionTools.expect(valid_user, "Expected valid user")
  end

  @doc """
    Test null safety guarantees

  """
  @spec test_null_safety() :: nil
  def test_null_safety() do
    maybe_null = nil
    safe_option = OptionTools.from_nullable(maybe_null)
    OptionTools.unwrap(OptionTools.map(safe_option, fn s -> s.length end), 0)
    OptionTools.is_some(safe_option)
    OptionTools.is_none(safe_option)
    OptionTools.to_nullable(safe_option)
  end

  @doc """
    Test collection operations with Option

  """
  @spec test_collection_operations() :: nil
  def test_collection_operations() do
    options = [{:ok, 1}, :error, {:ok, 3}, {:ok, 4}, :error]
    OptionTools.values(options)
    all_options = [{:ok, 1}, {:ok, 2}, {:ok, 3}]
    OptionTools.all(all_options)
    mixed_options = [{:ok, 1}, :error, {:ok, 3}]
    OptionTools.all(mixed_options)
    temp_array = nil
    temp_array1 = nil
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < options.length) do
          try do
            v = Enum.at(options, g)
          g = g + 1
          g ++ [OptionTools.map(v, fn x -> x * 2 end)]
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array1 = g
    g_array = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < temp_array1.length) do
          try do
            v = Enum.at(temp_array1, g)
          g = g + 1
          if (OptionTools.is_some(v)), do: g ++ [v], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    temp_array = g
  end

end
