defmodule AbstractFlag do
  @moduledoc """
  AbstractFlag enum generated from Haxe
  
  
  	Represents an abstract flag.
  
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :ab_enum |
    {:ab_from, term()} |
    {:ab_to, term()}

  @doc "Creates ab_enum enum value"
  @spec ab_enum() :: :ab_enum
  def ab_enum(), do: :ab_enum

  @doc """
  Creates ab_from enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec ab_from(term()) :: {:ab_from, term()}
  def ab_from(arg0) do
    {:ab_from, arg0}
  end

  @doc """
  Creates ab_to enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec ab_to(term()) :: {:ab_to, term()}
  def ab_to(arg0) do
    {:ab_to, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is ab_enum variant"
  @spec is_ab_enum(t()) :: boolean()
  def is_ab_enum(:ab_enum), do: true
  def is_ab_enum(_), do: false

  @doc "Returns true if value is ab_from variant"
  @spec is_ab_from(t()) :: boolean()
  def is_ab_from({:ab_from, _}), do: true
  def is_ab_from(_), do: false

  @doc "Returns true if value is ab_to variant"
  @spec is_ab_to(t()) :: boolean()
  def is_ab_to({:ab_to, _}), do: true
  def is_ab_to(_), do: false

  @doc "Extracts value from ab_from variant, returns {:ok, value} or :error"
  @spec get_ab_from_value(t()) :: {:ok, term()} | :error
  def get_ab_from_value({:ab_from, value}), do: {:ok, value}
  def get_ab_from_value(_), do: :error

  @doc "Extracts value from ab_to variant, returns {:ok, value} or :error"
  @spec get_ab_to_value(t()) :: {:ok, term()} | :error
  def get_ab_to_value({:ab_to, value}), do: {:ok, value}
  def get_ab_to_value(_), do: :error

end
