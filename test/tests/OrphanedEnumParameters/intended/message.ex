defmodule Message do
  @moduledoc """
  Message enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:created, term()} |
    {:updated, term(), term()} |
    {:deleted, term()} |
    :empty

  @doc """
  Creates created enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec created(term()) :: {:created, term()}
  def created(arg0) do
    {:created, arg0}
  end

  @doc """
  Creates updated enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec updated(term(), term()) :: {:updated, term(), term()}
  def updated(arg0, arg1) do
    {:updated, arg0, arg1}
  end

  @doc """
  Creates deleted enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec deleted(term()) :: {:deleted, term()}
  def deleted(arg0) do
    {:deleted, arg0}
  end

  @doc "Creates empty enum value"
  @spec empty() :: :empty
  def empty(), do: :empty

  # Predicate functions for pattern matching
  @doc "Returns true if value is created variant"
  @spec is_created(t()) :: boolean()
  def is_created({:created, _}), do: true
  def is_created(_), do: false

  @doc "Returns true if value is updated variant"
  @spec is_updated(t()) :: boolean()
  def is_updated({:updated, _}), do: true
  def is_updated(_), do: false

  @doc "Returns true if value is deleted variant"
  @spec is_deleted(t()) :: boolean()
  def is_deleted({:deleted, _}), do: true
  def is_deleted(_), do: false

  @doc "Returns true if value is empty variant"
  @spec is_empty(t()) :: boolean()
  def is_empty(:empty), do: true
  def is_empty(_), do: false

  @doc "Extracts value from created variant, returns {:ok, value} or :error"
  @spec get_created_value(t()) :: {:ok, term()} | :error
  def get_created_value({:created, value}), do: {:ok, value}
  def get_created_value(_), do: :error

  @doc "Extracts value from updated variant, returns {:ok, value} or :error"
  @spec get_updated_value(t()) :: {:ok, {term(), term()}} | :error
  def get_updated_value({:updated, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_updated_value(_), do: :error

  @doc "Extracts value from deleted variant, returns {:ok, value} or :error"
  @spec get_deleted_value(t()) :: {:ok, term()} | :error
  def get_deleted_value({:deleted, value}), do: {:ok, value}
  def get_deleted_value(_), do: :error

end
