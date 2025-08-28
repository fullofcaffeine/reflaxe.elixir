defmodule Access do
  @moduledoc """
  Access enum generated from Haxe
  
  
  	Represents an access modifier.
  	@see https://haxe.org/manual/class-field-access-modifier.html
  
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :a_public |
    :a_private |
    :a_static |
    :a_override |
    :a_dynamic |
    :a_inline |
    :a_macro |
    :a_final |
    :a_extern |
    :a_abstract |
    :a_overload

  @doc "Creates a_public enum value"
  @spec a_public() :: :a_public
  def a_public(), do: :a_public

  @doc "Creates a_private enum value"
  @spec a_private() :: :a_private
  def a_private(), do: :a_private

  @doc "Creates a_static enum value"
  @spec a_static() :: :a_static
  def a_static(), do: :a_static

  @doc "Creates a_override enum value"
  @spec a_override() :: :a_override
  def a_override(), do: :a_override

  @doc "Creates a_dynamic enum value"
  @spec a_dynamic() :: :a_dynamic
  def a_dynamic(), do: :a_dynamic

  @doc "Creates a_inline enum value"
  @spec a_inline() :: :a_inline
  def a_inline(), do: :a_inline

  @doc "Creates a_macro enum value"
  @spec a_macro() :: :a_macro
  def a_macro(), do: :a_macro

  @doc "Creates a_final enum value"
  @spec a_final() :: :a_final
  def a_final(), do: :a_final

  @doc "Creates a_extern enum value"
  @spec a_extern() :: :a_extern
  def a_extern(), do: :a_extern

  @doc "Creates a_abstract enum value"
  @spec a_abstract() :: :a_abstract
  def a_abstract(), do: :a_abstract

  @doc "Creates a_overload enum value"
  @spec a_overload() :: :a_overload
  def a_overload(), do: :a_overload

  # Predicate functions for pattern matching
  @doc "Returns true if value is a_public variant"
  @spec is_a_public(t()) :: boolean()
  def is_a_public(:a_public), do: true
  def is_a_public(_), do: false

  @doc "Returns true if value is a_private variant"
  @spec is_a_private(t()) :: boolean()
  def is_a_private(:a_private), do: true
  def is_a_private(_), do: false

  @doc "Returns true if value is a_static variant"
  @spec is_a_static(t()) :: boolean()
  def is_a_static(:a_static), do: true
  def is_a_static(_), do: false

  @doc "Returns true if value is a_override variant"
  @spec is_a_override(t()) :: boolean()
  def is_a_override(:a_override), do: true
  def is_a_override(_), do: false

  @doc "Returns true if value is a_dynamic variant"
  @spec is_a_dynamic(t()) :: boolean()
  def is_a_dynamic(:a_dynamic), do: true
  def is_a_dynamic(_), do: false

  @doc "Returns true if value is a_inline variant"
  @spec is_a_inline(t()) :: boolean()
  def is_a_inline(:a_inline), do: true
  def is_a_inline(_), do: false

  @doc "Returns true if value is a_macro variant"
  @spec is_a_macro(t()) :: boolean()
  def is_a_macro(:a_macro), do: true
  def is_a_macro(_), do: false

  @doc "Returns true if value is a_final variant"
  @spec is_a_final(t()) :: boolean()
  def is_a_final(:a_final), do: true
  def is_a_final(_), do: false

  @doc "Returns true if value is a_extern variant"
  @spec is_a_extern(t()) :: boolean()
  def is_a_extern(:a_extern), do: true
  def is_a_extern(_), do: false

  @doc "Returns true if value is a_abstract variant"
  @spec is_a_abstract(t()) :: boolean()
  def is_a_abstract(:a_abstract), do: true
  def is_a_abstract(_), do: false

  @doc "Returns true if value is a_overload variant"
  @spec is_a_overload(t()) :: boolean()
  def is_a_overload(:a_overload), do: true
  def is_a_overload(_), do: false

end
