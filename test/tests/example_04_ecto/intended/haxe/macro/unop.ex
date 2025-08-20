defmodule Unop do
  @moduledoc """
  Unop enum generated from Haxe
  
  
  	A unary operator.
  	@see https://haxe.org/manual/types-numeric-operators.html
  
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :op_increment |
    :op_decrement |
    :op_not |
    :op_neg |
    :op_neg_bits |
    :op_spread

  @doc "Creates op_increment enum value"
  @spec op_increment() :: :op_increment
  def op_increment(), do: :op_increment

  @doc "Creates op_decrement enum value"
  @spec op_decrement() :: :op_decrement
  def op_decrement(), do: :op_decrement

  @doc "Creates op_not enum value"
  @spec op_not() :: :op_not
  def op_not(), do: :op_not

  @doc "Creates op_neg enum value"
  @spec op_neg() :: :op_neg
  def op_neg(), do: :op_neg

  @doc "Creates op_neg_bits enum value"
  @spec op_neg_bits() :: :op_neg_bits
  def op_neg_bits(), do: :op_neg_bits

  @doc "Creates op_spread enum value"
  @spec op_spread() :: :op_spread
  def op_spread(), do: :op_spread

  # Predicate functions for pattern matching
  @doc "Returns true if value is op_increment variant"
  @spec is_op_increment(t()) :: boolean()
  def is_op_increment(:op_increment), do: true
  def is_op_increment(_), do: false

  @doc "Returns true if value is op_decrement variant"
  @spec is_op_decrement(t()) :: boolean()
  def is_op_decrement(:op_decrement), do: true
  def is_op_decrement(_), do: false

  @doc "Returns true if value is op_not variant"
  @spec is_op_not(t()) :: boolean()
  def is_op_not(:op_not), do: true
  def is_op_not(_), do: false

  @doc "Returns true if value is op_neg variant"
  @spec is_op_neg(t()) :: boolean()
  def is_op_neg(:op_neg), do: true
  def is_op_neg(_), do: false

  @doc "Returns true if value is op_neg_bits variant"
  @spec is_op_neg_bits(t()) :: boolean()
  def is_op_neg_bits(:op_neg_bits), do: true
  def is_op_neg_bits(_), do: false

  @doc "Returns true if value is op_spread variant"
  @spec is_op_spread(t()) :: boolean()
  def is_op_spread(:op_spread), do: true
  def is_op_spread(_), do: false

end
