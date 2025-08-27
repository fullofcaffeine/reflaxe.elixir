ExUnit.start()

# Test helper utilities for Mix project integration tests
defmodule TestHelpers do
  @moduledoc """
  Helper functions for testing Haxe-compiled modules in Mix projects.
  """
  
  @doc """
  Creates sample user data for testing purposes.
  """
  def sample_user_data(overrides \\ %{}) do
    Map.merge(%{
      name: "John Doe",
      email: "john@example.com", 
      age: 30
    }, overrides)
  end
  
  @doc """
  Asserts that a result is a successful {:ok, value} tuple.
  """
  def assert_ok({:ok, value}), do: value
  def assert_ok(result), do: raise "Expected {:ok, _}, got: #{inspect(result)}"
  
  @doc """
  Asserts that a result is an error {:error, reason} tuple.
  """
  def assert_error({:error, reason}), do: reason
  def assert_error(result), do: raise "Expected {:error, _}, got: #{inspect(result)}"
  
  @doc """
  Asserts that a validation result is valid.
  """
  def assert_valid_result(result) do
    assert result.valid == true, "Expected valid result, got: #{inspect(result)}"
    result
  end
  
  @doc """
  Asserts that a validation result is invalid.
  """
  def assert_invalid_result(result) do
    assert result.valid == false, "Expected invalid result, got: #{inspect(result)}"
    result
  end
  
  @doc """
  Measures execution time of a function.
  Useful for performance testing of compiled Haxe modules.
  """
  def measure_time(fun) do
    {time, result} = :timer.tc(fun)
    {time / 1000, result}  # Return time in milliseconds
  end
  
  @doc """
  Generates random test data for various data types.
  """
  def random_string(length \\ 10) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode64()
    |> String.slice(0, length)
  end
  
  def random_email do
    username = random_string(8) |> String.downcase()
    domain = random_string(5) |> String.downcase()
    "#{username}@#{domain}.com"
  end
  
  def random_number(min \\ 1, max \\ 100) do
    :rand.uniform(max - min + 1) + min - 1
  end
  
  @doc """
  Creates multiple test cases for batch testing.
  """
  def create_test_cases(count, generator_fun) do
    1..count |> Enum.map(fn _ -> generator_fun.() end)
  end
end

# Import test helpers into all test modules
defmodule ExUnit.CaseTemplate do
  use ExUnit.CaseTemplate
  
  using do
    quote do
      import TestHelpers
    end
  end
end