defmodule ComparisonOperator do
  @moduledoc """
  ComparisonOperator enum generated from Haxe
  
  
   * Comparison operators for joins and conditions
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :equal |
    :not_equal |
    :greater_than |
    :greater_than_or_equal |
    :less_than |
    :less_than_or_equal |
    {:in_, term()} |
    {:like, term()} |
    :is_null |
    :is_not_null

  @doc "Creates equal enum value"
  @spec equal() :: :equal
  def equal(), do: :equal

  @doc "Creates not_equal enum value"
  @spec not_equal() :: :not_equal
  def not_equal(), do: :not_equal

  @doc "Creates greater_than enum value"
  @spec greater_than() :: :greater_than
  def greater_than(), do: :greater_than

  @doc "Creates greater_than_or_equal enum value"
  @spec greater_than_or_equal() :: :greater_than_or_equal
  def greater_than_or_equal(), do: :greater_than_or_equal

  @doc "Creates less_than enum value"
  @spec less_than() :: :less_than
  def less_than(), do: :less_than

  @doc "Creates less_than_or_equal enum value"
  @spec less_than_or_equal() :: :less_than_or_equal
  def less_than_or_equal(), do: :less_than_or_equal

  @doc """
  Creates in_ enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec in_(term()) :: {:in_, term()}
  def in_(arg0) do
    {:in_, arg0}
  end

  @doc """
  Creates like enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec like(term()) :: {:like, term()}
  def like(arg0) do
    {:like, arg0}
  end

  @doc "Creates is_null enum value"
  @spec is_null() :: :is_null
  def is_null(), do: :is_null

  @doc "Creates is_not_null enum value"
  @spec is_not_null() :: :is_not_null
  def is_not_null(), do: :is_not_null

  # Predicate functions for pattern matching
  @doc "Returns true if value is equal variant"
  @spec is_equal(t()) :: boolean()
  def is_equal(:equal), do: true
  def is_equal(_), do: false

  @doc "Returns true if value is not_equal variant"
  @spec is_not_equal(t()) :: boolean()
  def is_not_equal(:not_equal), do: true
  def is_not_equal(_), do: false

  @doc "Returns true if value is greater_than variant"
  @spec is_greater_than(t()) :: boolean()
  def is_greater_than(:greater_than), do: true
  def is_greater_than(_), do: false

  @doc "Returns true if value is greater_than_or_equal variant"
  @spec is_greater_than_or_equal(t()) :: boolean()
  def is_greater_than_or_equal(:greater_than_or_equal), do: true
  def is_greater_than_or_equal(_), do: false

  @doc "Returns true if value is less_than variant"
  @spec is_less_than(t()) :: boolean()
  def is_less_than(:less_than), do: true
  def is_less_than(_), do: false

  @doc "Returns true if value is less_than_or_equal variant"
  @spec is_less_than_or_equal(t()) :: boolean()
  def is_less_than_or_equal(:less_than_or_equal), do: true
  def is_less_than_or_equal(_), do: false

  @doc "Returns true if value is in_ variant"
  @spec is_in_(t()) :: boolean()
  def is_in_({:in_, _}), do: true
  def is_in_(_), do: false

  @doc "Returns true if value is like variant"
  @spec is_like(t()) :: boolean()
  def is_like({:like, _}), do: true
  def is_like(_), do: false

  @doc "Returns true if value is is_null variant"
  @spec is_is_null(t()) :: boolean()
  def is_is_null(:is_null), do: true
  def is_is_null(_), do: false

  @doc "Returns true if value is is_not_null variant"
  @spec is_is_not_null(t()) :: boolean()
  def is_is_not_null(:is_not_null), do: true
  def is_is_not_null(_), do: false

  @doc "Extracts value from in_ variant, returns {:ok, value} or :error"
  @spec get_in__value(t()) :: {:ok, term()} | :error
  def get_in__value({:in_, value}), do: {:ok, value}
  def get_in__value(_), do: :error

  @doc "Extracts value from like variant, returns {:ok, value} or :error"
  @spec get_like_value(t()) :: {:ok, term()} | :error
  def get_like_value({:like, value}), do: {:ok, value}
  def get_like_value(_), do: :error

end
