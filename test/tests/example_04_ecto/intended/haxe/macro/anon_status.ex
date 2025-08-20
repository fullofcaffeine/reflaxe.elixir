defmodule AnonStatus do
  @moduledoc """
  AnonStatus enum generated from Haxe
  
  
  	Represents the kind of the anonymous structure type.
  
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :a_closed |
    :a_opened |
    :a_const |
    {:a_extend, term()} |
    {:a_class_statics, term()} |
    {:a_enum_statics, term()} |
    {:a_abstract_statics, term()}

  @doc "Creates a_closed enum value"
  @spec a_closed() :: :a_closed
  def a_closed(), do: :a_closed

  @doc "Creates a_opened enum value"
  @spec a_opened() :: :a_opened
  def a_opened(), do: :a_opened

  @doc "Creates a_const enum value"
  @spec a_const() :: :a_const
  def a_const(), do: :a_const

  @doc """
  Creates a_extend enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec a_extend(term()) :: {:a_extend, term()}
  def a_extend(arg0) do
    {:a_extend, arg0}
  end

  @doc """
  Creates a_class_statics enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec a_class_statics(term()) :: {:a_class_statics, term()}
  def a_class_statics(arg0) do
    {:a_class_statics, arg0}
  end

  @doc """
  Creates a_enum_statics enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec a_enum_statics(term()) :: {:a_enum_statics, term()}
  def a_enum_statics(arg0) do
    {:a_enum_statics, arg0}
  end

  @doc """
  Creates a_abstract_statics enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec a_abstract_statics(term()) :: {:a_abstract_statics, term()}
  def a_abstract_statics(arg0) do
    {:a_abstract_statics, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is a_closed variant"
  @spec is_a_closed(t()) :: boolean()
  def is_a_closed(:a_closed), do: true
  def is_a_closed(_), do: false

  @doc "Returns true if value is a_opened variant"
  @spec is_a_opened(t()) :: boolean()
  def is_a_opened(:a_opened), do: true
  def is_a_opened(_), do: false

  @doc "Returns true if value is a_const variant"
  @spec is_a_const(t()) :: boolean()
  def is_a_const(:a_const), do: true
  def is_a_const(_), do: false

  @doc "Returns true if value is a_extend variant"
  @spec is_a_extend(t()) :: boolean()
  def is_a_extend({:a_extend, _}), do: true
  def is_a_extend(_), do: false

  @doc "Returns true if value is a_class_statics variant"
  @spec is_a_class_statics(t()) :: boolean()
  def is_a_class_statics({:a_class_statics, _}), do: true
  def is_a_class_statics(_), do: false

  @doc "Returns true if value is a_enum_statics variant"
  @spec is_a_enum_statics(t()) :: boolean()
  def is_a_enum_statics({:a_enum_statics, _}), do: true
  def is_a_enum_statics(_), do: false

  @doc "Returns true if value is a_abstract_statics variant"
  @spec is_a_abstract_statics(t()) :: boolean()
  def is_a_abstract_statics({:a_abstract_statics, _}), do: true
  def is_a_abstract_statics(_), do: false

  @doc "Extracts value from a_extend variant, returns {:ok, value} or :error"
  @spec get_a_extend_value(t()) :: {:ok, term()} | :error
  def get_a_extend_value({:a_extend, value}), do: {:ok, value}
  def get_a_extend_value(_), do: :error

  @doc "Extracts value from a_class_statics variant, returns {:ok, value} or :error"
  @spec get_a_class_statics_value(t()) :: {:ok, term()} | :error
  def get_a_class_statics_value({:a_class_statics, value}), do: {:ok, value}
  def get_a_class_statics_value(_), do: :error

  @doc "Extracts value from a_enum_statics variant, returns {:ok, value} or :error"
  @spec get_a_enum_statics_value(t()) :: {:ok, term()} | :error
  def get_a_enum_statics_value({:a_enum_statics, value}), do: {:ok, value}
  def get_a_enum_statics_value(_), do: :error

  @doc "Extracts value from a_abstract_statics variant, returns {:ok, value} or :error"
  @spec get_a_abstract_statics_value(t()) :: {:ok, term()} | :error
  def get_a_abstract_statics_value({:a_abstract_statics, value}), do: {:ok, value}
  def get_a_abstract_statics_value(_), do: :error

end
