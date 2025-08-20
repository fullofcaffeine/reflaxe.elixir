defmodule ConnState do
  @moduledoc """
  ConnState enum generated from Haxe
  
  
   * Connection state
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :unset |
    :set |
    :sent |
    :chunked |
    :file_chunked

  @doc "Creates unset enum value"
  @spec unset() :: :unset
  def unset(), do: :unset

  @doc "Creates set enum value"
  @spec set() :: :set
  def set(), do: :set

  @doc "Creates sent enum value"
  @spec sent() :: :sent
  def sent(), do: :sent

  @doc "Creates chunked enum value"
  @spec chunked() :: :chunked
  def chunked(), do: :chunked

  @doc "Creates file_chunked enum value"
  @spec file_chunked() :: :file_chunked
  def file_chunked(), do: :file_chunked

  # Predicate functions for pattern matching
  @doc "Returns true if value is unset variant"
  @spec is_unset(t()) :: boolean()
  def is_unset(:unset), do: true
  def is_unset(_), do: false

  @doc "Returns true if value is set variant"
  @spec is_set(t()) :: boolean()
  def is_set(:set), do: true
  def is_set(_), do: false

  @doc "Returns true if value is sent variant"
  @spec is_sent(t()) :: boolean()
  def is_sent(:sent), do: true
  def is_sent(_), do: false

  @doc "Returns true if value is chunked variant"
  @spec is_chunked(t()) :: boolean()
  def is_chunked(:chunked), do: true
  def is_chunked(_), do: false

  @doc "Returns true if value is file_chunked variant"
  @spec is_file_chunked(t()) :: boolean()
  def is_file_chunked(:file_chunked), do: true
  def is_file_chunked(_), do: false

end
