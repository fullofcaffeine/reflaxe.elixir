defmodule Encoding do
  @moduledoc """
  Encoding enum generated from Haxe
  
  
	String binary encoding supported by Haxe I/O

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :u_t_f8 |
    :raw_native

  @doc "Creates u_t_f8 enum value"
  @spec u_t_f8() :: :u_t_f8
  def u_t_f8(), do: :u_t_f8

  @doc "Creates raw_native enum value"
  @spec raw_native() :: :raw_native
  def raw_native(), do: :raw_native

  # Predicate functions for pattern matching
  @doc "Returns true if value is u_t_f8 variant"
  @spec is_u_t_f8(t()) :: boolean()
  def is_u_t_f8(:u_t_f8), do: true
  def is_u_t_f8(_), do: false

  @doc "Returns true if value is raw_native variant"
  @spec is_raw_native(t()) :: boolean()
  def is_raw_native(:raw_native), do: true
  def is_raw_native(_), do: false

end
