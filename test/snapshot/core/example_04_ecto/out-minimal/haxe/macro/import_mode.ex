defmodule ImportMode do
  @moduledoc """
  ImportMode enum generated from Haxe
  
  
  	Represents the import mode.
  	@see https://haxe.org/manual/type-system-import.html
  
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :i_normal |
    {:i_as_name, term()} |
    :i_all

  @doc "Creates i_normal enum value"
  @spec i_normal() :: :i_normal
  def i_normal(), do: :i_normal

  @doc """
  Creates i_as_name enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec i_as_name(term()) :: {:i_as_name, term()}
  def i_as_name(arg0) do
    {:i_as_name, arg0}
  end

  @doc "Creates i_all enum value"
  @spec i_all() :: :i_all
  def i_all(), do: :i_all

  # Predicate functions for pattern matching
  @doc "Returns true if value is i_normal variant"
  @spec is_i_normal(t()) :: boolean()
  def is_i_normal(:i_normal), do: true
  def is_i_normal(_), do: false

  @doc "Returns true if value is i_as_name variant"
  @spec is_i_as_name(t()) :: boolean()
  def is_i_as_name({:i_as_name, _}), do: true
  def is_i_as_name(_), do: false

  @doc "Returns true if value is i_all variant"
  @spec is_i_all(t()) :: boolean()
  def is_i_all(:i_all), do: true
  def is_i_all(_), do: false

  @doc "Extracts value from i_as_name variant, returns {:ok, value} or :error"
  @spec get_i_as_name_value(t()) :: {:ok, term()} | :error
  def get_i_as_name_value({:i_as_name, value}), do: {:ok, value}
  def get_i_as_name_value(_), do: :error

end
