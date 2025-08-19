defmodule RouteHelper do
  @moduledoc """
  RouteHelper enum generated from Haxe
  
  
 * Route helper identifier
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:named, term()} |
    {:path, term()}

  @doc """
  Creates named enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec named(term()) :: {:named, term()}
  def named(arg0) do
    {:named, arg0}
  end

  @doc """
  Creates path enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec path(term()) :: {:path, term()}
  def path(arg0) do
    {:path, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is named variant"
  @spec is_named(t()) :: boolean()
  def is_named({:named, _}), do: true
  def is_named(_), do: false

  @doc "Returns true if value is path variant"
  @spec is_path(t()) :: boolean()
  def is_path({:path, _}), do: true
  def is_path(_), do: false

  @doc "Extracts value from named variant, returns {:ok, value} or :error"
  @spec get_named_value(t()) :: {:ok, term()} | :error
  def get_named_value({:named, value}), do: {:ok, value}
  def get_named_value(_), do: :error

  @doc "Extracts value from path variant, returns {:ok, value} or :error"
  @spec get_path_value(t()) :: {:ok, term()} | :error
  def get_path_value({:path, value}), do: {:ok, value}
  def get_path_value(_), do: :error

end
