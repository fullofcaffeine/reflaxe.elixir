defmodule Container do
  @moduledoc """
  Container enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:box, term()} |
    {:list, term()} |
    :empty

  @doc """
  Creates box enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec box(term()) :: {:box, term()}
  def box(arg0) do
    {:box, arg0}
  end

  @doc """
  Creates list enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec list(term()) :: {:list, term()}
  def list(arg0) do
    {:list, arg0}
  end

  @doc "Creates empty enum value"
  @spec empty() :: :empty
  def empty(), do: :empty

  # Predicate functions for pattern matching
  @doc "Returns true if value is box variant"
  @spec is_box(t()) :: boolean()
  def is_box({:box, _}), do: true
  def is_box(_), do: false

  @doc "Returns true if value is list variant"
  @spec is_list(t()) :: boolean()
  def is_list({:list, _}), do: true
  def is_list(_), do: false

  @doc "Returns true if value is empty variant"
  @spec is_empty(t()) :: boolean()
  def is_empty(:empty), do: true
  def is_empty(_), do: false

  @doc "Extracts value from box variant, returns {:ok, value} or :error"
  @spec get_box_value(t()) :: {:ok, term()} | :error
  def get_box_value({:box, value}), do: {:ok, value}
  def get_box_value(_), do: :error

  @doc "Extracts value from list variant, returns {:ok, value} or :error"
  @spec get_list_value(t()) :: {:ok, term()} | :error
  def get_list_value({:list, value}), do: {:ok, value}
  def get_list_value(_), do: :error

end
