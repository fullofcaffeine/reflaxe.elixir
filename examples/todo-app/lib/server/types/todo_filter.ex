defmodule TodoFilter do
  @moduledoc """
  TodoFilter enum generated from Haxe
  
  
 * Todo filter options
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :all |
    :active |
    :completed |
    {:by_tag, term()} |
    {:by_priority, term()} |
    {:by_due_date, term()}

  @doc "Creates all enum value"
  @spec all() :: :all
  def all(), do: :all

  @doc "Creates active enum value"
  @spec active() :: :active
  def active(), do: :active

  @doc "Creates completed enum value"
  @spec completed() :: :completed
  def completed(), do: :completed

  @doc """
  Creates by_tag enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec by_tag(term()) :: {:by_tag, term()}
  def by_tag(arg0) do
    {:by_tag, arg0}
  end

  @doc """
  Creates by_priority enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec by_priority(term()) :: {:by_priority, term()}
  def by_priority(arg0) do
    {:by_priority, arg0}
  end

  @doc """
  Creates by_due_date enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec by_due_date(term()) :: {:by_due_date, term()}
  def by_due_date(arg0) do
    {:by_due_date, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is all variant"
  @spec is_all(t()) :: boolean()
  def is_all(:all), do: true
  def is_all(_), do: false

  @doc "Returns true if value is active variant"
  @spec is_active(t()) :: boolean()
  def is_active(:active), do: true
  def is_active(_), do: false

  @doc "Returns true if value is completed variant"
  @spec is_completed(t()) :: boolean()
  def is_completed(:completed), do: true
  def is_completed(_), do: false

  @doc "Returns true if value is by_tag variant"
  @spec is_by_tag(t()) :: boolean()
  def is_by_tag({:by_tag, _}), do: true
  def is_by_tag(_), do: false

  @doc "Returns true if value is by_priority variant"
  @spec is_by_priority(t()) :: boolean()
  def is_by_priority({:by_priority, _}), do: true
  def is_by_priority(_), do: false

  @doc "Returns true if value is by_due_date variant"
  @spec is_by_due_date(t()) :: boolean()
  def is_by_due_date({:by_due_date, _}), do: true
  def is_by_due_date(_), do: false

  @doc "Extracts value from by_tag variant, returns {:ok, value} or :error"
  @spec get_by_tag_value(t()) :: {:ok, term()} | :error
  def get_by_tag_value({:by_tag, value}), do: {:ok, value}
  def get_by_tag_value(_), do: :error

  @doc "Extracts value from by_priority variant, returns {:ok, value} or :error"
  @spec get_by_priority_value(t()) :: {:ok, term()} | :error
  def get_by_priority_value({:by_priority, value}), do: {:ok, value}
  def get_by_priority_value(_), do: :error

  @doc "Extracts value from by_due_date variant, returns {:ok, value} or :error"
  @spec get_by_due_date_value(t()) :: {:ok, term()} | :error
  def get_by_due_date_value({:by_due_date, value}), do: {:ok, value}
  def get_by_due_date_value(_), do: :error

end
