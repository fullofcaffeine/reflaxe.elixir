defmodule BulkOperation do
  @moduledoc """
  BulkOperation enum generated from Haxe
  
  
   * Bulk operation types
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :complete_all |
    :delete_completed |
    {:set_priority, term()} |
    {:add_tag, term()} |
    {:remove_tag, term()}

  @doc "Creates complete_all enum value"
  @spec complete_all() :: :complete_all
  def complete_all(), do: :complete_all

  @doc "Creates delete_completed enum value"
  @spec delete_completed() :: :delete_completed
  def delete_completed(), do: :delete_completed

  @doc """
  Creates set_priority enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec set_priority(term()) :: {:set_priority, term()}
  def set_priority(arg0) do
    {:set_priority, arg0}
  end

  @doc """
  Creates add_tag enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec add_tag(term()) :: {:add_tag, term()}
  def add_tag(arg0) do
    {:add_tag, arg0}
  end

  @doc """
  Creates remove_tag enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec remove_tag(term()) :: {:remove_tag, term()}
  def remove_tag(arg0) do
    {:remove_tag, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is complete_all variant"
  @spec is_complete_all(t()) :: boolean()
  def is_complete_all(:complete_all), do: true
  def is_complete_all(_), do: false

  @doc "Returns true if value is delete_completed variant"
  @spec is_delete_completed(t()) :: boolean()
  def is_delete_completed(:delete_completed), do: true
  def is_delete_completed(_), do: false

  @doc "Returns true if value is set_priority variant"
  @spec is_set_priority(t()) :: boolean()
  def is_set_priority({:set_priority, _}), do: true
  def is_set_priority(_), do: false

  @doc "Returns true if value is add_tag variant"
  @spec is_add_tag(t()) :: boolean()
  def is_add_tag({:add_tag, _}), do: true
  def is_add_tag(_), do: false

  @doc "Returns true if value is remove_tag variant"
  @spec is_remove_tag(t()) :: boolean()
  def is_remove_tag({:remove_tag, _}), do: true
  def is_remove_tag(_), do: false

  @doc "Extracts value from set_priority variant, returns {:ok, value} or :error"
  @spec get_set_priority_value(t()) :: {:ok, term()} | :error
  def get_set_priority_value({:set_priority, value}), do: {:ok, value}
  def get_set_priority_value(_), do: :error

  @doc "Extracts value from add_tag variant, returns {:ok, value} or :error"
  @spec get_add_tag_value(t()) :: {:ok, term()} | :error
  def get_add_tag_value({:add_tag, value}), do: {:ok, value}
  def get_add_tag_value(_), do: :error

  @doc "Extracts value from remove_tag variant, returns {:ok, value} or :error"
  @spec get_remove_tag_value(t()) :: {:ok, term()} | :error
  def get_remove_tag_value({:remove_tag, value}), do: {:ok, value}
  def get_remove_tag_value(_), do: :error

end
