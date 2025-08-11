defmodule MathHelper do
  @moduledoc """
  MathHelper - Demonstrates pipe operators and functional composition
  
  This example showcases Elixir-style pipe operators (|>) for
  functional composition, making code more readable and maintainable.
  """

  @doc """
  Basic pipe operator demonstration
  Shows how data flows through a pipeline of transformations
  """
  def process_number(x) do
    x
    |> multiply_by_two()
    |> add_ten()
    |> Float.round()
  end

  @doc """
  Complex pipeline with conditional logic
  Demonstrates pipe operators with branching
  """
  def calculate_discount(price, customer_type) do
    price
    |> apply_base_discount()
    |> apply_customer_discount(customer_type)
    |> apply_minimum_price()
    |> Float.round()
  end

  @doc """
  String processing pipeline
  Shows pipe operators work with different data types
  """
  def format_user_name(name) do
    name
    |> String.trim()
    |> String.downcase()
    |> capitalize_first()
  end

  @doc """
  Data validation pipeline
  Common pattern in Elixir for validation chains
  """
  def validate_and_process(input) do
    input
    |> validate_not_empty()
    |> validate_length()
    |> sanitize_input()
    |> process_input()
  end

  # Helper functions used in pipelines

  def multiply_by_two(x), do: x * 2
  def add_ten(x), do: x + 10
  def apply_base_discount(price), do: price * 0.9

  def apply_customer_discount(price, customer_type) do
    case customer_type do
      "premium" -> price * 0.8
      "regular" -> price * 0.95
      _ -> price
    end
  end

  def apply_minimum_price(price), do: max(price, 5.0)

  def capitalize_first(""), do: ""
  def capitalize_first(str) do
    String.upcase(String.at(str, 0)) <> String.slice(str, 1..-1)
  end

  def validate_not_empty(input) when input in [nil, ""], do: raise("Input cannot be empty")
  def validate_not_empty(input), do: input

  def validate_length(input) when byte_size(input) > 100, do: raise("Input too long")
  def validate_length(input), do: input

  def sanitize_input(input), do: String.replace(input, "<", "")
  def process_input(input), do: "Processed: #{input}"
end