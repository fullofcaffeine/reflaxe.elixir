defmodule TodoSort do
  @moduledoc """
  TodoSort enum generated from Haxe
  
  
 * Todo sort options
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :created |
    :priority |
    :due_date |
    :title |
    :status

  @doc "Creates created enum value"
  @spec created() :: :created
  def created(), do: :created

  @doc "Creates priority enum value"
  @spec priority() :: :priority
  def priority(), do: :priority

  @doc "Creates due_date enum value"
  @spec due_date() :: :due_date
  def due_date(), do: :due_date

  @doc "Creates title enum value"
  @spec title() :: :title
  def title(), do: :title

  @doc "Creates status enum value"
  @spec status() :: :status
  def status(), do: :status

  # Predicate functions for pattern matching
  @doc "Returns true if value is created variant"
  @spec is_created(t()) :: boolean()
  def is_created(:created), do: true
  def is_created(_), do: false

  @doc "Returns true if value is priority variant"
  @spec is_priority(t()) :: boolean()
  def is_priority(:priority), do: true
  def is_priority(_), do: false

  @doc "Returns true if value is due_date variant"
  @spec is_due_date(t()) :: boolean()
  def is_due_date(:due_date), do: true
  def is_due_date(_), do: false

  @doc "Returns true if value is title variant"
  @spec is_title(t()) :: boolean()
  def is_title(:title), do: true
  def is_title(_), do: false

  @doc "Returns true if value is status variant"
  @spec is_status(t()) :: boolean()
  def is_status(:status), do: true
  def is_status(_), do: false

end
