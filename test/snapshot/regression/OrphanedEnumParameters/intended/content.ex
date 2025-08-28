defmodule Content do
  @moduledoc """
  Content enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:text, term()} |
    {:number, term()} |
    :empty

  @doc """
  Creates text enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec text(term()) :: {:text, term()}
  def text(arg0) do
    {:text, arg0}
  end

  @doc """
  Creates number enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec number(term()) :: {:number, term()}
  def number(arg0) do
    {:number, arg0}
  end

  @doc "Creates empty enum value"
  @spec empty() :: :empty
  def empty(), do: :empty

  # Predicate functions for pattern matching
  @doc "Returns true if value is text variant"
  @spec is_text(t()) :: boolean()
  def is_text({:text, _}), do: true
  def is_text(_), do: false

  @doc "Returns true if value is number variant"
  @spec is_number(t()) :: boolean()
  def is_number({:number, _}), do: true
  def is_number(_), do: false

  @doc "Returns true if value is empty variant"
  @spec is_empty(t()) :: boolean()
  def is_empty(:empty), do: true
  def is_empty(_), do: false

  @doc "Extracts value from text variant, returns {:ok, value} or :error"
  @spec get_text_value(t()) :: {:ok, term()} | :error
  def get_text_value({:text, value}), do: {:ok, value}
  def get_text_value(_), do: :error

  @doc "Extracts value from number variant, returns {:ok, value} or :error"
  @spec get_number_value(t()) :: {:ok, term()} | :error
  def get_number_value({:number, value}), do: {:ok, value}
  def get_number_value(_), do: :error

end
