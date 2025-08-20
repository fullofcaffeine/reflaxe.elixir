defmodule VarAccess do
  @moduledoc """
  VarAccess enum generated from Haxe
  
  
  	Represents the variable accessor.
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :acc_normal |
    :acc_no |
    :acc_never |
    :acc_resolve |
    :acc_call |
    :acc_inline |
    {:acc_require, term(), term()} |
    :acc_ctor

  @doc "Creates acc_normal enum value"
  @spec acc_normal() :: :acc_normal
  def acc_normal(), do: :acc_normal

  @doc "Creates acc_no enum value"
  @spec acc_no() :: :acc_no
  def acc_no(), do: :acc_no

  @doc "Creates acc_never enum value"
  @spec acc_never() :: :acc_never
  def acc_never(), do: :acc_never

  @doc "Creates acc_resolve enum value"
  @spec acc_resolve() :: :acc_resolve
  def acc_resolve(), do: :acc_resolve

  @doc "Creates acc_call enum value"
  @spec acc_call() :: :acc_call
  def acc_call(), do: :acc_call

  @doc "Creates acc_inline enum value"
  @spec acc_inline() :: :acc_inline
  def acc_inline(), do: :acc_inline

  @doc """
  Creates acc_require enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec acc_require(term(), term()) :: {:acc_require, term(), term()}
  def acc_require(arg0, arg1) do
    {:acc_require, arg0, arg1}
  end

  @doc "Creates acc_ctor enum value"
  @spec acc_ctor() :: :acc_ctor
  def acc_ctor(), do: :acc_ctor

  # Predicate functions for pattern matching
  @doc "Returns true if value is acc_normal variant"
  @spec is_acc_normal(t()) :: boolean()
  def is_acc_normal(:acc_normal), do: true
  def is_acc_normal(_), do: false

  @doc "Returns true if value is acc_no variant"
  @spec is_acc_no(t()) :: boolean()
  def is_acc_no(:acc_no), do: true
  def is_acc_no(_), do: false

  @doc "Returns true if value is acc_never variant"
  @spec is_acc_never(t()) :: boolean()
  def is_acc_never(:acc_never), do: true
  def is_acc_never(_), do: false

  @doc "Returns true if value is acc_resolve variant"
  @spec is_acc_resolve(t()) :: boolean()
  def is_acc_resolve(:acc_resolve), do: true
  def is_acc_resolve(_), do: false

  @doc "Returns true if value is acc_call variant"
  @spec is_acc_call(t()) :: boolean()
  def is_acc_call(:acc_call), do: true
  def is_acc_call(_), do: false

  @doc "Returns true if value is acc_inline variant"
  @spec is_acc_inline(t()) :: boolean()
  def is_acc_inline(:acc_inline), do: true
  def is_acc_inline(_), do: false

  @doc "Returns true if value is acc_require variant"
  @spec is_acc_require(t()) :: boolean()
  def is_acc_require({:acc_require, _}), do: true
  def is_acc_require(_), do: false

  @doc "Returns true if value is acc_ctor variant"
  @spec is_acc_ctor(t()) :: boolean()
  def is_acc_ctor(:acc_ctor), do: true
  def is_acc_ctor(_), do: false

  @doc "Extracts value from acc_require variant, returns {:ok, value} or :error"
  @spec get_acc_require_value(t()) :: {:ok, {term(), term()}} | :error
  def get_acc_require_value({:acc_require, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_acc_require_value(_), do: :error

end
