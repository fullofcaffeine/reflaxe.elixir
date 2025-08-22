defmodule ConstraintDefinition do
  @moduledoc """
  ConstraintDefinition enum generated from Haxe
  
  
   * Constraint definition
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:check, term()} |
    {:unique, term()} |
    {:foreign_key, term(), term()} |
    {:exclude, term()}

  @doc """
  Creates check enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec check(term()) :: {:check, term()}
  def check(arg0) do
    {:check, arg0}
  end

  @doc """
  Creates unique enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec unique(term()) :: {:unique, term()}
  def unique(arg0) do
    {:unique, arg0}
  end

  @doc """
  Creates foreign_key enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec foreign_key(term(), term()) :: {:foreign_key, term(), term()}
  def foreign_key(arg0, arg1) do
    {:foreign_key, arg0, arg1}
  end

  @doc """
  Creates exclude enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec exclude(term()) :: {:exclude, term()}
  def exclude(arg0) do
    {:exclude, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is check variant"
  @spec is_check(t()) :: boolean()
  def is_check({:check, _}), do: true
  def is_check(_), do: false

  @doc "Returns true if value is unique variant"
  @spec is_unique(t()) :: boolean()
  def is_unique({:unique, _}), do: true
  def is_unique(_), do: false

  @doc "Returns true if value is foreign_key variant"
  @spec is_foreign_key(t()) :: boolean()
  def is_foreign_key({:foreign_key, _}), do: true
  def is_foreign_key(_), do: false

  @doc "Returns true if value is exclude variant"
  @spec is_exclude(t()) :: boolean()
  def is_exclude({:exclude, _}), do: true
  def is_exclude(_), do: false

  @doc "Extracts value from check variant, returns {:ok, value} or :error"
  @spec get_check_value(t()) :: {:ok, term()} | :error
  def get_check_value({:check, value}), do: {:ok, value}
  def get_check_value(_), do: :error

  @doc "Extracts value from unique variant, returns {:ok, value} or :error"
  @spec get_unique_value(t()) :: {:ok, term()} | :error
  def get_unique_value({:unique, value}), do: {:ok, value}
  def get_unique_value(_), do: :error

  @doc "Extracts value from foreign_key variant, returns {:ok, value} or :error"
  @spec get_foreign_key_value(t()) :: {:ok, {term(), term()}} | :error
  def get_foreign_key_value({:foreign_key, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_foreign_key_value(_), do: :error

  @doc "Extracts value from exclude variant, returns {:ok, value} or :error"
  @spec get_exclude_value(t()) :: {:ok, term()} | :error
  def get_exclude_value({:exclude, value}), do: {:ok, value}
  def get_exclude_value(_), do: :error

end
