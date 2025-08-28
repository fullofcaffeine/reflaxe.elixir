defmodule MethodKind do
  @moduledoc """
  MethodKind enum generated from Haxe
  
  
  	Represents the method kind.
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :meth_normal |
    :meth_inline |
    :meth_dynamic |
    :meth_macro

  @doc "Creates meth_normal enum value"
  @spec meth_normal() :: :meth_normal
  def meth_normal(), do: :meth_normal

  @doc "Creates meth_inline enum value"
  @spec meth_inline() :: :meth_inline
  def meth_inline(), do: :meth_inline

  @doc "Creates meth_dynamic enum value"
  @spec meth_dynamic() :: :meth_dynamic
  def meth_dynamic(), do: :meth_dynamic

  @doc "Creates meth_macro enum value"
  @spec meth_macro() :: :meth_macro
  def meth_macro(), do: :meth_macro

  # Predicate functions for pattern matching
  @doc "Returns true if value is meth_normal variant"
  @spec is_meth_normal(t()) :: boolean()
  def is_meth_normal(:meth_normal), do: true
  def is_meth_normal(_), do: false

  @doc "Returns true if value is meth_inline variant"
  @spec is_meth_inline(t()) :: boolean()
  def is_meth_inline(:meth_inline), do: true
  def is_meth_inline(_), do: false

  @doc "Returns true if value is meth_dynamic variant"
  @spec is_meth_dynamic(t()) :: boolean()
  def is_meth_dynamic(:meth_dynamic), do: true
  def is_meth_dynamic(_), do: false

  @doc "Returns true if value is meth_macro variant"
  @spec is_meth_macro(t()) :: boolean()
  def is_meth_macro(:meth_macro), do: true
  def is_meth_macro(_), do: false

end
