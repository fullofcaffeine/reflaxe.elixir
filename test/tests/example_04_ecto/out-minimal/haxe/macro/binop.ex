defmodule Binop do
  @moduledoc """
  Binop enum generated from Haxe
  
  
  	A binary operator.
  	@see https://haxe.org/manual/types-numeric-operators.html
  
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :op_add |
    :op_mult |
    :op_div |
    :op_sub |
    :op_assign |
    :op_eq |
    :op_not_eq |
    :op_gt |
    :op_gte |
    :op_lt |
    :op_lte |
    :op_and |
    :op_or |
    :op_xor |
    :op_bool_and |
    :op_bool_or |
    :op_shl |
    :op_shr |
    :op_u_shr |
    :op_mod |
    {:op_assign_op, term()} |
    :op_interval |
    :op_arrow |
    :op_in |
    :op_null_coal

  @doc "Creates op_add enum value"
  @spec op_add() :: :op_add
  def op_add(), do: :op_add

  @doc "Creates op_mult enum value"
  @spec op_mult() :: :op_mult
  def op_mult(), do: :op_mult

  @doc "Creates op_div enum value"
  @spec op_div() :: :op_div
  def op_div(), do: :op_div

  @doc "Creates op_sub enum value"
  @spec op_sub() :: :op_sub
  def op_sub(), do: :op_sub

  @doc "Creates op_assign enum value"
  @spec op_assign() :: :op_assign
  def op_assign(), do: :op_assign

  @doc "Creates op_eq enum value"
  @spec op_eq() :: :op_eq
  def op_eq(), do: :op_eq

  @doc "Creates op_not_eq enum value"
  @spec op_not_eq() :: :op_not_eq
  def op_not_eq(), do: :op_not_eq

  @doc "Creates op_gt enum value"
  @spec op_gt() :: :op_gt
  def op_gt(), do: :op_gt

  @doc "Creates op_gte enum value"
  @spec op_gte() :: :op_gte
  def op_gte(), do: :op_gte

  @doc "Creates op_lt enum value"
  @spec op_lt() :: :op_lt
  def op_lt(), do: :op_lt

  @doc "Creates op_lte enum value"
  @spec op_lte() :: :op_lte
  def op_lte(), do: :op_lte

  @doc "Creates op_and enum value"
  @spec op_and() :: :op_and
  def op_and(), do: :op_and

  @doc "Creates op_or enum value"
  @spec op_or() :: :op_or
  def op_or(), do: :op_or

  @doc "Creates op_xor enum value"
  @spec op_xor() :: :op_xor
  def op_xor(), do: :op_xor

  @doc "Creates op_bool_and enum value"
  @spec op_bool_and() :: :op_bool_and
  def op_bool_and(), do: :op_bool_and

  @doc "Creates op_bool_or enum value"
  @spec op_bool_or() :: :op_bool_or
  def op_bool_or(), do: :op_bool_or

  @doc "Creates op_shl enum value"
  @spec op_shl() :: :op_shl
  def op_shl(), do: :op_shl

  @doc "Creates op_shr enum value"
  @spec op_shr() :: :op_shr
  def op_shr(), do: :op_shr

  @doc "Creates op_u_shr enum value"
  @spec op_u_shr() :: :op_u_shr
  def op_u_shr(), do: :op_u_shr

  @doc "Creates op_mod enum value"
  @spec op_mod() :: :op_mod
  def op_mod(), do: :op_mod

  @doc """
  Creates op_assign_op enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec op_assign_op(term()) :: {:op_assign_op, term()}
  def op_assign_op(arg0) do
    {:op_assign_op, arg0}
  end

  @doc "Creates op_interval enum value"
  @spec op_interval() :: :op_interval
  def op_interval(), do: :op_interval

  @doc "Creates op_arrow enum value"
  @spec op_arrow() :: :op_arrow
  def op_arrow(), do: :op_arrow

  @doc "Creates op_in enum value"
  @spec op_in() :: :op_in
  def op_in(), do: :op_in

  @doc "Creates op_null_coal enum value"
  @spec op_null_coal() :: :op_null_coal
  def op_null_coal(), do: :op_null_coal

  # Predicate functions for pattern matching
  @doc "Returns true if value is op_add variant"
  @spec is_op_add(t()) :: boolean()
  def is_op_add(:op_add), do: true
  def is_op_add(_), do: false

  @doc "Returns true if value is op_mult variant"
  @spec is_op_mult(t()) :: boolean()
  def is_op_mult(:op_mult), do: true
  def is_op_mult(_), do: false

  @doc "Returns true if value is op_div variant"
  @spec is_op_div(t()) :: boolean()
  def is_op_div(:op_div), do: true
  def is_op_div(_), do: false

  @doc "Returns true if value is op_sub variant"
  @spec is_op_sub(t()) :: boolean()
  def is_op_sub(:op_sub), do: true
  def is_op_sub(_), do: false

  @doc "Returns true if value is op_assign variant"
  @spec is_op_assign(t()) :: boolean()
  def is_op_assign(:op_assign), do: true
  def is_op_assign(_), do: false

  @doc "Returns true if value is op_eq variant"
  @spec is_op_eq(t()) :: boolean()
  def is_op_eq(:op_eq), do: true
  def is_op_eq(_), do: false

  @doc "Returns true if value is op_not_eq variant"
  @spec is_op_not_eq(t()) :: boolean()
  def is_op_not_eq(:op_not_eq), do: true
  def is_op_not_eq(_), do: false

  @doc "Returns true if value is op_gt variant"
  @spec is_op_gt(t()) :: boolean()
  def is_op_gt(:op_gt), do: true
  def is_op_gt(_), do: false

  @doc "Returns true if value is op_gte variant"
  @spec is_op_gte(t()) :: boolean()
  def is_op_gte(:op_gte), do: true
  def is_op_gte(_), do: false

  @doc "Returns true if value is op_lt variant"
  @spec is_op_lt(t()) :: boolean()
  def is_op_lt(:op_lt), do: true
  def is_op_lt(_), do: false

  @doc "Returns true if value is op_lte variant"
  @spec is_op_lte(t()) :: boolean()
  def is_op_lte(:op_lte), do: true
  def is_op_lte(_), do: false

  @doc "Returns true if value is op_and variant"
  @spec is_op_and(t()) :: boolean()
  def is_op_and(:op_and), do: true
  def is_op_and(_), do: false

  @doc "Returns true if value is op_or variant"
  @spec is_op_or(t()) :: boolean()
  def is_op_or(:op_or), do: true
  def is_op_or(_), do: false

  @doc "Returns true if value is op_xor variant"
  @spec is_op_xor(t()) :: boolean()
  def is_op_xor(:op_xor), do: true
  def is_op_xor(_), do: false

  @doc "Returns true if value is op_bool_and variant"
  @spec is_op_bool_and(t()) :: boolean()
  def is_op_bool_and(:op_bool_and), do: true
  def is_op_bool_and(_), do: false

  @doc "Returns true if value is op_bool_or variant"
  @spec is_op_bool_or(t()) :: boolean()
  def is_op_bool_or(:op_bool_or), do: true
  def is_op_bool_or(_), do: false

  @doc "Returns true if value is op_shl variant"
  @spec is_op_shl(t()) :: boolean()
  def is_op_shl(:op_shl), do: true
  def is_op_shl(_), do: false

  @doc "Returns true if value is op_shr variant"
  @spec is_op_shr(t()) :: boolean()
  def is_op_shr(:op_shr), do: true
  def is_op_shr(_), do: false

  @doc "Returns true if value is op_u_shr variant"
  @spec is_op_u_shr(t()) :: boolean()
  def is_op_u_shr(:op_u_shr), do: true
  def is_op_u_shr(_), do: false

  @doc "Returns true if value is op_mod variant"
  @spec is_op_mod(t()) :: boolean()
  def is_op_mod(:op_mod), do: true
  def is_op_mod(_), do: false

  @doc "Returns true if value is op_assign_op variant"
  @spec is_op_assign_op(t()) :: boolean()
  def is_op_assign_op({:op_assign_op, _}), do: true
  def is_op_assign_op(_), do: false

  @doc "Returns true if value is op_interval variant"
  @spec is_op_interval(t()) :: boolean()
  def is_op_interval(:op_interval), do: true
  def is_op_interval(_), do: false

  @doc "Returns true if value is op_arrow variant"
  @spec is_op_arrow(t()) :: boolean()
  def is_op_arrow(:op_arrow), do: true
  def is_op_arrow(_), do: false

  @doc "Returns true if value is op_in variant"
  @spec is_op_in(t()) :: boolean()
  def is_op_in(:op_in), do: true
  def is_op_in(_), do: false

  @doc "Returns true if value is op_null_coal variant"
  @spec is_op_null_coal(t()) :: boolean()
  def is_op_null_coal(:op_null_coal), do: true
  def is_op_null_coal(_), do: false

  @doc "Extracts value from op_assign_op variant, returns {:ok, value} or :error"
  @spec get_op_assign_op_value(t()) :: {:ok, term()} | :error
  def get_op_assign_op_value({:op_assign_op, value}), do: {:ok, value}
  def get_op_assign_op_value(_), do: :error

end
