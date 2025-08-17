defmodule Error do
  @moduledoc """
    Error module generated from Haxe

      This error can be used to handle or produce compilation errors in macros.
  """

end


defmodule StringLiteralKind do
  @moduledoc """
  StringLiteralKind enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :double_quotes |
    :single_quotes

  @doc "Creates double_quotes enum value"
  @spec double_quotes() :: :double_quotes
  def double_quotes(), do: :double_quotes

  @doc "Creates single_quotes enum value"
  @spec single_quotes() :: :single_quotes
  def single_quotes(), do: :single_quotes

  # Predicate functions for pattern matching
  @doc "Returns true if value is double_quotes variant"
  @spec is_double_quotes(t()) :: boolean()
  def is_double_quotes(:double_quotes), do: true
  def is_double_quotes(_), do: false

  @doc "Returns true if value is single_quotes variant"
  @spec is_single_quotes(t()) :: boolean()
  def is_single_quotes(:single_quotes), do: true
  def is_single_quotes(_), do: false

end


defmodule Constant do
  @moduledoc """
  Constant enum generated from Haxe
  
  
	Represents a constant.
	@see https://haxe.org/manual/expression-constants.html

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:c_int, term(), term()} |
    {:c_float, term(), term()} |
    {:c_string, term(), term()} |
    {:c_ident, term()} |
    {:c_regexp, term(), term()}

  @doc """
  Creates c_int enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec c_int(term(), term()) :: {:c_int, term(), term()}
  def c_int(arg0, arg1) do
    {:c_int, arg0, arg1}
  end

  @doc """
  Creates c_float enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec c_float(term(), term()) :: {:c_float, term(), term()}
  def c_float(arg0, arg1) do
    {:c_float, arg0, arg1}
  end

  @doc """
  Creates c_string enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec c_string(term(), term()) :: {:c_string, term(), term()}
  def c_string(arg0, arg1) do
    {:c_string, arg0, arg1}
  end

  @doc """
  Creates c_ident enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec c_ident(term()) :: {:c_ident, term()}
  def c_ident(arg0) do
    {:c_ident, arg0}
  end

  @doc """
  Creates c_regexp enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec c_regexp(term(), term()) :: {:c_regexp, term(), term()}
  def c_regexp(arg0, arg1) do
    {:c_regexp, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is c_int variant"
  @spec is_c_int(t()) :: boolean()
  def is_c_int({:c_int, _}), do: true
  def is_c_int(_), do: false

  @doc "Returns true if value is c_float variant"
  @spec is_c_float(t()) :: boolean()
  def is_c_float({:c_float, _}), do: true
  def is_c_float(_), do: false

  @doc "Returns true if value is c_string variant"
  @spec is_c_string(t()) :: boolean()
  def is_c_string({:c_string, _}), do: true
  def is_c_string(_), do: false

  @doc "Returns true if value is c_ident variant"
  @spec is_c_ident(t()) :: boolean()
  def is_c_ident({:c_ident, _}), do: true
  def is_c_ident(_), do: false

  @doc "Returns true if value is c_regexp variant"
  @spec is_c_regexp(t()) :: boolean()
  def is_c_regexp({:c_regexp, _}), do: true
  def is_c_regexp(_), do: false

  @doc "Extracts value from c_int variant, returns {:ok, value} or :error"
  @spec get_c_int_value(t()) :: {:ok, {term(), term()}} | :error
  def get_c_int_value({:c_int, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_c_int_value(_), do: :error

  @doc "Extracts value from c_float variant, returns {:ok, value} or :error"
  @spec get_c_float_value(t()) :: {:ok, {term(), term()}} | :error
  def get_c_float_value({:c_float, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_c_float_value(_), do: :error

  @doc "Extracts value from c_string variant, returns {:ok, value} or :error"
  @spec get_c_string_value(t()) :: {:ok, {term(), term()}} | :error
  def get_c_string_value({:c_string, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_c_string_value(_), do: :error

  @doc "Extracts value from c_ident variant, returns {:ok, value} or :error"
  @spec get_c_ident_value(t()) :: {:ok, term()} | :error
  def get_c_ident_value({:c_ident, value}), do: {:ok, value}
  def get_c_ident_value(_), do: :error

  @doc "Extracts value from c_regexp variant, returns {:ok, value} or :error"
  @spec get_c_regexp_value(t()) :: {:ok, {term(), term()}} | :error
  def get_c_regexp_value({:c_regexp, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_c_regexp_value(_), do: :error

end


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


defmodule EFieldKind do
  @moduledoc """
  EFieldKind enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :normal |
    :safe

  @doc "Creates normal enum value"
  @spec normal() :: :normal
  def normal(), do: :normal

  @doc "Creates safe enum value"
  @spec safe() :: :safe
  def safe(), do: :safe

  # Predicate functions for pattern matching
  @doc "Returns true if value is normal variant"
  @spec is_normal(t()) :: boolean()
  def is_normal(:normal), do: true
  def is_normal(_), do: false

  @doc "Returns true if value is safe variant"
  @spec is_safe(t()) :: boolean()
  def is_safe(:safe), do: true
  def is_safe(_), do: false

end


defmodule QuoteStatus do
  @moduledoc """
  QuoteStatus enum generated from Haxe
  
  
	Represents the way something is quoted.

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :unquoted |
    :quoted

  @doc "Creates unquoted enum value"
  @spec unquoted() :: :unquoted
  def unquoted(), do: :unquoted

  @doc "Creates quoted enum value"
  @spec quoted() :: :quoted
  def quoted(), do: :quoted

  # Predicate functions for pattern matching
  @doc "Returns true if value is unquoted variant"
  @spec is_unquoted(t()) :: boolean()
  def is_unquoted(:unquoted), do: true
  def is_unquoted(_), do: false

  @doc "Returns true if value is quoted variant"
  @spec is_quoted(t()) :: boolean()
  def is_quoted(:quoted), do: true
  def is_quoted(_), do: false

end


defmodule FunctionKind do
  @moduledoc """
  FunctionKind enum generated from Haxe
  
  
	Represents function kind in the AST

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :f_anonymous |
    {:f_named, term(), term()} |
    :f_arrow

  @doc "Creates f_anonymous enum value"
  @spec f_anonymous() :: :f_anonymous
  def f_anonymous(), do: :f_anonymous

  @doc """
  Creates f_named enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_named(term(), term()) :: {:f_named, term(), term()}
  def f_named(arg0, arg1) do
    {:f_named, arg0, arg1}
  end

  @doc "Creates f_arrow enum value"
  @spec f_arrow() :: :f_arrow
  def f_arrow(), do: :f_arrow

  # Predicate functions for pattern matching
  @doc "Returns true if value is f_anonymous variant"
  @spec is_f_anonymous(t()) :: boolean()
  def is_f_anonymous(:f_anonymous), do: true
  def is_f_anonymous(_), do: false

  @doc "Returns true if value is f_named variant"
  @spec is_f_named(t()) :: boolean()
  def is_f_named({:f_named, _}), do: true
  def is_f_named(_), do: false

  @doc "Returns true if value is f_arrow variant"
  @spec is_f_arrow(t()) :: boolean()
  def is_f_arrow(:f_arrow), do: true
  def is_f_arrow(_), do: false

  @doc "Extracts value from f_named variant, returns {:ok, value} or :error"
  @spec get_f_named_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_named_value({:f_named, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_named_value(_), do: :error

end


defmodule ExprDef do
  @moduledoc """
  ExprDef enum generated from Haxe
  
  
	Represents the kind of a node in the AST.

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:e_const, term()} |
    {:e_array, term(), term()} |
    {:e_binop, term(), term(), term()} |
    {:e_field, term(), term(), term()} |
    {:e_parenthesis, term()} |
    {:e_object_decl, term()} |
    {:e_array_decl, term()} |
    {:e_call, term(), term()} |
    {:e_new, term(), term()} |
    {:e_unop, term(), term(), term()} |
    {:e_vars, term()} |
    {:e_function, term(), term()} |
    {:e_block, term()} |
    {:e_for, term(), term()} |
    {:e_if, term(), term(), term()} |
    {:e_while, term(), term(), term()} |
    {:e_switch, term(), term(), term()} |
    {:e_try, term(), term()} |
    {:e_return, term()} |
    :e_break |
    :e_continue |
    {:e_untyped, term()} |
    {:e_throw, term()} |
    {:e_cast, term(), term()} |
    {:e_display, term(), term()} |
    {:e_ternary, term(), term(), term()} |
    {:e_check_type, term(), term()} |
    {:e_meta, term(), term()} |
    {:e_is, term(), term()}

  @doc """
  Creates e_const enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec e_const(term()) :: {:e_const, term()}
  def e_const(arg0) do
    {:e_const, arg0}
  end

  @doc """
  Creates e_array enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_array(term(), term()) :: {:e_array, term(), term()}
  def e_array(arg0, arg1) do
    {:e_array, arg0, arg1}
  end

  @doc """
  Creates e_binop enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec e_binop(term(), term(), term()) :: {:e_binop, term(), term(), term()}
  def e_binop(arg0, arg1, arg2) do
    {:e_binop, arg0, arg1, arg2}
  end

  @doc """
  Creates e_field enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec e_field(term(), term(), term()) :: {:e_field, term(), term(), term()}
  def e_field(arg0, arg1, arg2) do
    {:e_field, arg0, arg1, arg2}
  end

  @doc """
  Creates e_parenthesis enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec e_parenthesis(term()) :: {:e_parenthesis, term()}
  def e_parenthesis(arg0) do
    {:e_parenthesis, arg0}
  end

  @doc """
  Creates e_object_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec e_object_decl(term()) :: {:e_object_decl, term()}
  def e_object_decl(arg0) do
    {:e_object_decl, arg0}
  end

  @doc """
  Creates e_array_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec e_array_decl(term()) :: {:e_array_decl, term()}
  def e_array_decl(arg0) do
    {:e_array_decl, arg0}
  end

  @doc """
  Creates e_call enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_call(term(), term()) :: {:e_call, term(), term()}
  def e_call(arg0, arg1) do
    {:e_call, arg0, arg1}
  end

  @doc """
  Creates e_new enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_new(term(), term()) :: {:e_new, term(), term()}
  def e_new(arg0, arg1) do
    {:e_new, arg0, arg1}
  end

  @doc """
  Creates e_unop enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec e_unop(term(), term(), term()) :: {:e_unop, term(), term(), term()}
  def e_unop(arg0, arg1, arg2) do
    {:e_unop, arg0, arg1, arg2}
  end

  @doc """
  Creates e_vars enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec e_vars(term()) :: {:e_vars, term()}
  def e_vars(arg0) do
    {:e_vars, arg0}
  end

  @doc """
  Creates e_function enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_function(term(), term()) :: {:e_function, term(), term()}
  def e_function(arg0, arg1) do
    {:e_function, arg0, arg1}
  end

  @doc """
  Creates e_block enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec e_block(term()) :: {:e_block, term()}
  def e_block(arg0) do
    {:e_block, arg0}
  end

  @doc """
  Creates e_for enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_for(term(), term()) :: {:e_for, term(), term()}
  def e_for(arg0, arg1) do
    {:e_for, arg0, arg1}
  end

  @doc """
  Creates e_if enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec e_if(term(), term(), term()) :: {:e_if, term(), term(), term()}
  def e_if(arg0, arg1, arg2) do
    {:e_if, arg0, arg1, arg2}
  end

  @doc """
  Creates e_while enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec e_while(term(), term(), term()) :: {:e_while, term(), term(), term()}
  def e_while(arg0, arg1, arg2) do
    {:e_while, arg0, arg1, arg2}
  end

  @doc """
  Creates e_switch enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec e_switch(term(), term(), term()) :: {:e_switch, term(), term(), term()}
  def e_switch(arg0, arg1, arg2) do
    {:e_switch, arg0, arg1, arg2}
  end

  @doc """
  Creates e_try enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_try(term(), term()) :: {:e_try, term(), term()}
  def e_try(arg0, arg1) do
    {:e_try, arg0, arg1}
  end

  @doc """
  Creates e_return enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec e_return(term()) :: {:e_return, term()}
  def e_return(arg0) do
    {:e_return, arg0}
  end

  @doc "Creates e_break enum value"
  @spec e_break() :: :e_break
  def e_break(), do: :e_break

  @doc "Creates e_continue enum value"
  @spec e_continue() :: :e_continue
  def e_continue(), do: :e_continue

  @doc """
  Creates e_untyped enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec e_untyped(term()) :: {:e_untyped, term()}
  def e_untyped(arg0) do
    {:e_untyped, arg0}
  end

  @doc """
  Creates e_throw enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec e_throw(term()) :: {:e_throw, term()}
  def e_throw(arg0) do
    {:e_throw, arg0}
  end

  @doc """
  Creates e_cast enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_cast(term(), term()) :: {:e_cast, term(), term()}
  def e_cast(arg0, arg1) do
    {:e_cast, arg0, arg1}
  end

  @doc """
  Creates e_display enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_display(term(), term()) :: {:e_display, term(), term()}
  def e_display(arg0, arg1) do
    {:e_display, arg0, arg1}
  end

  @doc """
  Creates e_ternary enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec e_ternary(term(), term(), term()) :: {:e_ternary, term(), term(), term()}
  def e_ternary(arg0, arg1, arg2) do
    {:e_ternary, arg0, arg1, arg2}
  end

  @doc """
  Creates e_check_type enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_check_type(term(), term()) :: {:e_check_type, term(), term()}
  def e_check_type(arg0, arg1) do
    {:e_check_type, arg0, arg1}
  end

  @doc """
  Creates e_meta enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_meta(term(), term()) :: {:e_meta, term(), term()}
  def e_meta(arg0, arg1) do
    {:e_meta, arg0, arg1}
  end

  @doc """
  Creates e_is enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec e_is(term(), term()) :: {:e_is, term(), term()}
  def e_is(arg0, arg1) do
    {:e_is, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is e_const variant"
  @spec is_e_const(t()) :: boolean()
  def is_e_const({:e_const, _}), do: true
  def is_e_const(_), do: false

  @doc "Returns true if value is e_array variant"
  @spec is_e_array(t()) :: boolean()
  def is_e_array({:e_array, _}), do: true
  def is_e_array(_), do: false

  @doc "Returns true if value is e_binop variant"
  @spec is_e_binop(t()) :: boolean()
  def is_e_binop({:e_binop, _}), do: true
  def is_e_binop(_), do: false

  @doc "Returns true if value is e_field variant"
  @spec is_e_field(t()) :: boolean()
  def is_e_field({:e_field, _}), do: true
  def is_e_field(_), do: false

  @doc "Returns true if value is e_parenthesis variant"
  @spec is_e_parenthesis(t()) :: boolean()
  def is_e_parenthesis({:e_parenthesis, _}), do: true
  def is_e_parenthesis(_), do: false

  @doc "Returns true if value is e_object_decl variant"
  @spec is_e_object_decl(t()) :: boolean()
  def is_e_object_decl({:e_object_decl, _}), do: true
  def is_e_object_decl(_), do: false

  @doc "Returns true if value is e_array_decl variant"
  @spec is_e_array_decl(t()) :: boolean()
  def is_e_array_decl({:e_array_decl, _}), do: true
  def is_e_array_decl(_), do: false

  @doc "Returns true if value is e_call variant"
  @spec is_e_call(t()) :: boolean()
  def is_e_call({:e_call, _}), do: true
  def is_e_call(_), do: false

  @doc "Returns true if value is e_new variant"
  @spec is_e_new(t()) :: boolean()
  def is_e_new({:e_new, _}), do: true
  def is_e_new(_), do: false

  @doc "Returns true if value is e_unop variant"
  @spec is_e_unop(t()) :: boolean()
  def is_e_unop({:e_unop, _}), do: true
  def is_e_unop(_), do: false

  @doc "Returns true if value is e_vars variant"
  @spec is_e_vars(t()) :: boolean()
  def is_e_vars({:e_vars, _}), do: true
  def is_e_vars(_), do: false

  @doc "Returns true if value is e_function variant"
  @spec is_e_function(t()) :: boolean()
  def is_e_function({:e_function, _}), do: true
  def is_e_function(_), do: false

  @doc "Returns true if value is e_block variant"
  @spec is_e_block(t()) :: boolean()
  def is_e_block({:e_block, _}), do: true
  def is_e_block(_), do: false

  @doc "Returns true if value is e_for variant"
  @spec is_e_for(t()) :: boolean()
  def is_e_for({:e_for, _}), do: true
  def is_e_for(_), do: false

  @doc "Returns true if value is e_if variant"
  @spec is_e_if(t()) :: boolean()
  def is_e_if({:e_if, _}), do: true
  def is_e_if(_), do: false

  @doc "Returns true if value is e_while variant"
  @spec is_e_while(t()) :: boolean()
  def is_e_while({:e_while, _}), do: true
  def is_e_while(_), do: false

  @doc "Returns true if value is e_switch variant"
  @spec is_e_switch(t()) :: boolean()
  def is_e_switch({:e_switch, _}), do: true
  def is_e_switch(_), do: false

  @doc "Returns true if value is e_try variant"
  @spec is_e_try(t()) :: boolean()
  def is_e_try({:e_try, _}), do: true
  def is_e_try(_), do: false

  @doc "Returns true if value is e_return variant"
  @spec is_e_return(t()) :: boolean()
  def is_e_return({:e_return, _}), do: true
  def is_e_return(_), do: false

  @doc "Returns true if value is e_break variant"
  @spec is_e_break(t()) :: boolean()
  def is_e_break(:e_break), do: true
  def is_e_break(_), do: false

  @doc "Returns true if value is e_continue variant"
  @spec is_e_continue(t()) :: boolean()
  def is_e_continue(:e_continue), do: true
  def is_e_continue(_), do: false

  @doc "Returns true if value is e_untyped variant"
  @spec is_e_untyped(t()) :: boolean()
  def is_e_untyped({:e_untyped, _}), do: true
  def is_e_untyped(_), do: false

  @doc "Returns true if value is e_throw variant"
  @spec is_e_throw(t()) :: boolean()
  def is_e_throw({:e_throw, _}), do: true
  def is_e_throw(_), do: false

  @doc "Returns true if value is e_cast variant"
  @spec is_e_cast(t()) :: boolean()
  def is_e_cast({:e_cast, _}), do: true
  def is_e_cast(_), do: false

  @doc "Returns true if value is e_display variant"
  @spec is_e_display(t()) :: boolean()
  def is_e_display({:e_display, _}), do: true
  def is_e_display(_), do: false

  @doc "Returns true if value is e_ternary variant"
  @spec is_e_ternary(t()) :: boolean()
  def is_e_ternary({:e_ternary, _}), do: true
  def is_e_ternary(_), do: false

  @doc "Returns true if value is e_check_type variant"
  @spec is_e_check_type(t()) :: boolean()
  def is_e_check_type({:e_check_type, _}), do: true
  def is_e_check_type(_), do: false

  @doc "Returns true if value is e_meta variant"
  @spec is_e_meta(t()) :: boolean()
  def is_e_meta({:e_meta, _}), do: true
  def is_e_meta(_), do: false

  @doc "Returns true if value is e_is variant"
  @spec is_e_is(t()) :: boolean()
  def is_e_is({:e_is, _}), do: true
  def is_e_is(_), do: false

  @doc "Extracts value from e_const variant, returns {:ok, value} or :error"
  @spec get_e_const_value(t()) :: {:ok, term()} | :error
  def get_e_const_value({:e_const, value}), do: {:ok, value}
  def get_e_const_value(_), do: :error

  @doc "Extracts value from e_array variant, returns {:ok, value} or :error"
  @spec get_e_array_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_array_value({:e_array, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_array_value(_), do: :error

  @doc "Extracts value from e_binop variant, returns {:ok, value} or :error"
  @spec get_e_binop_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_e_binop_value({:e_binop, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_e_binop_value(_), do: :error

  @doc "Extracts value from e_field variant, returns {:ok, value} or :error"
  @spec get_e_field_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_e_field_value({:e_field, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_e_field_value(_), do: :error

  @doc "Extracts value from e_parenthesis variant, returns {:ok, value} or :error"
  @spec get_e_parenthesis_value(t()) :: {:ok, term()} | :error
  def get_e_parenthesis_value({:e_parenthesis, value}), do: {:ok, value}
  def get_e_parenthesis_value(_), do: :error

  @doc "Extracts value from e_object_decl variant, returns {:ok, value} or :error"
  @spec get_e_object_decl_value(t()) :: {:ok, term()} | :error
  def get_e_object_decl_value({:e_object_decl, value}), do: {:ok, value}
  def get_e_object_decl_value(_), do: :error

  @doc "Extracts value from e_array_decl variant, returns {:ok, value} or :error"
  @spec get_e_array_decl_value(t()) :: {:ok, term()} | :error
  def get_e_array_decl_value({:e_array_decl, value}), do: {:ok, value}
  def get_e_array_decl_value(_), do: :error

  @doc "Extracts value from e_call variant, returns {:ok, value} or :error"
  @spec get_e_call_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_call_value({:e_call, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_call_value(_), do: :error

  @doc "Extracts value from e_new variant, returns {:ok, value} or :error"
  @spec get_e_new_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_new_value({:e_new, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_new_value(_), do: :error

  @doc "Extracts value from e_unop variant, returns {:ok, value} or :error"
  @spec get_e_unop_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_e_unop_value({:e_unop, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_e_unop_value(_), do: :error

  @doc "Extracts value from e_vars variant, returns {:ok, value} or :error"
  @spec get_e_vars_value(t()) :: {:ok, term()} | :error
  def get_e_vars_value({:e_vars, value}), do: {:ok, value}
  def get_e_vars_value(_), do: :error

  @doc "Extracts value from e_function variant, returns {:ok, value} or :error"
  @spec get_e_function_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_function_value({:e_function, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_function_value(_), do: :error

  @doc "Extracts value from e_block variant, returns {:ok, value} or :error"
  @spec get_e_block_value(t()) :: {:ok, term()} | :error
  def get_e_block_value({:e_block, value}), do: {:ok, value}
  def get_e_block_value(_), do: :error

  @doc "Extracts value from e_for variant, returns {:ok, value} or :error"
  @spec get_e_for_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_for_value({:e_for, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_for_value(_), do: :error

  @doc "Extracts value from e_if variant, returns {:ok, value} or :error"
  @spec get_e_if_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_e_if_value({:e_if, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_e_if_value(_), do: :error

  @doc "Extracts value from e_while variant, returns {:ok, value} or :error"
  @spec get_e_while_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_e_while_value({:e_while, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_e_while_value(_), do: :error

  @doc "Extracts value from e_switch variant, returns {:ok, value} or :error"
  @spec get_e_switch_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_e_switch_value({:e_switch, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_e_switch_value(_), do: :error

  @doc "Extracts value from e_try variant, returns {:ok, value} or :error"
  @spec get_e_try_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_try_value({:e_try, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_try_value(_), do: :error

  @doc "Extracts value from e_return variant, returns {:ok, value} or :error"
  @spec get_e_return_value(t()) :: {:ok, term()} | :error
  def get_e_return_value({:e_return, value}), do: {:ok, value}
  def get_e_return_value(_), do: :error

  @doc "Extracts value from e_untyped variant, returns {:ok, value} or :error"
  @spec get_e_untyped_value(t()) :: {:ok, term()} | :error
  def get_e_untyped_value({:e_untyped, value}), do: {:ok, value}
  def get_e_untyped_value(_), do: :error

  @doc "Extracts value from e_throw variant, returns {:ok, value} or :error"
  @spec get_e_throw_value(t()) :: {:ok, term()} | :error
  def get_e_throw_value({:e_throw, value}), do: {:ok, value}
  def get_e_throw_value(_), do: :error

  @doc "Extracts value from e_cast variant, returns {:ok, value} or :error"
  @spec get_e_cast_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_cast_value({:e_cast, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_cast_value(_), do: :error

  @doc "Extracts value from e_display variant, returns {:ok, value} or :error"
  @spec get_e_display_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_display_value({:e_display, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_display_value(_), do: :error

  @doc "Extracts value from e_ternary variant, returns {:ok, value} or :error"
  @spec get_e_ternary_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_e_ternary_value({:e_ternary, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_e_ternary_value(_), do: :error

  @doc "Extracts value from e_check_type variant, returns {:ok, value} or :error"
  @spec get_e_check_type_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_check_type_value({:e_check_type, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_check_type_value(_), do: :error

  @doc "Extracts value from e_meta variant, returns {:ok, value} or :error"
  @spec get_e_meta_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_meta_value({:e_meta, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_meta_value(_), do: :error

  @doc "Extracts value from e_is variant, returns {:ok, value} or :error"
  @spec get_e_is_value(t()) :: {:ok, {term(), term()}} | :error
  def get_e_is_value({:e_is, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_e_is_value(_), do: :error

end


defmodule DisplayKind do
  @moduledoc """
  DisplayKind enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :d_k_call |
    :d_k_dot |
    :d_k_structure |
    :d_k_marked |
    {:d_k_pattern, term()}

  @doc "Creates d_k_call enum value"
  @spec d_k_call() :: :d_k_call
  def d_k_call(), do: :d_k_call

  @doc "Creates d_k_dot enum value"
  @spec d_k_dot() :: :d_k_dot
  def d_k_dot(), do: :d_k_dot

  @doc "Creates d_k_structure enum value"
  @spec d_k_structure() :: :d_k_structure
  def d_k_structure(), do: :d_k_structure

  @doc "Creates d_k_marked enum value"
  @spec d_k_marked() :: :d_k_marked
  def d_k_marked(), do: :d_k_marked

  @doc """
  Creates d_k_pattern enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec d_k_pattern(term()) :: {:d_k_pattern, term()}
  def d_k_pattern(arg0) do
    {:d_k_pattern, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is d_k_call variant"
  @spec is_d_k_call(t()) :: boolean()
  def is_d_k_call(:d_k_call), do: true
  def is_d_k_call(_), do: false

  @doc "Returns true if value is d_k_dot variant"
  @spec is_d_k_dot(t()) :: boolean()
  def is_d_k_dot(:d_k_dot), do: true
  def is_d_k_dot(_), do: false

  @doc "Returns true if value is d_k_structure variant"
  @spec is_d_k_structure(t()) :: boolean()
  def is_d_k_structure(:d_k_structure), do: true
  def is_d_k_structure(_), do: false

  @doc "Returns true if value is d_k_marked variant"
  @spec is_d_k_marked(t()) :: boolean()
  def is_d_k_marked(:d_k_marked), do: true
  def is_d_k_marked(_), do: false

  @doc "Returns true if value is d_k_pattern variant"
  @spec is_d_k_pattern(t()) :: boolean()
  def is_d_k_pattern({:d_k_pattern, _}), do: true
  def is_d_k_pattern(_), do: false

  @doc "Extracts value from d_k_pattern variant, returns {:ok, value} or :error"
  @spec get_d_k_pattern_value(t()) :: {:ok, term()} | :error
  def get_d_k_pattern_value({:d_k_pattern, value}), do: {:ok, value}
  def get_d_k_pattern_value(_), do: :error

end


defmodule ComplexType do
  @moduledoc """
  ComplexType enum generated from Haxe
  
  
	Represents a type syntax in the AST.

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:t_path, term()} |
    {:t_function, term(), term()} |
    {:t_anonymous, term()} |
    {:t_parent, term()} |
    {:t_extend, term(), term()} |
    {:t_optional, term()} |
    {:t_named, term(), term()} |
    {:t_intersection, term()}

  @doc """
  Creates t_path enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_path(term()) :: {:t_path, term()}
  def t_path(arg0) do
    {:t_path, arg0}
  end

  @doc """
  Creates t_function enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_function(term(), term()) :: {:t_function, term(), term()}
  def t_function(arg0, arg1) do
    {:t_function, arg0, arg1}
  end

  @doc """
  Creates t_anonymous enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_anonymous(term()) :: {:t_anonymous, term()}
  def t_anonymous(arg0) do
    {:t_anonymous, arg0}
  end

  @doc """
  Creates t_parent enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_parent(term()) :: {:t_parent, term()}
  def t_parent(arg0) do
    {:t_parent, arg0}
  end

  @doc """
  Creates t_extend enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_extend(term(), term()) :: {:t_extend, term(), term()}
  def t_extend(arg0, arg1) do
    {:t_extend, arg0, arg1}
  end

  @doc """
  Creates t_optional enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_optional(term()) :: {:t_optional, term()}
  def t_optional(arg0) do
    {:t_optional, arg0}
  end

  @doc """
  Creates t_named enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_named(term(), term()) :: {:t_named, term(), term()}
  def t_named(arg0, arg1) do
    {:t_named, arg0, arg1}
  end

  @doc """
  Creates t_intersection enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_intersection(term()) :: {:t_intersection, term()}
  def t_intersection(arg0) do
    {:t_intersection, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_path variant"
  @spec is_t_path(t()) :: boolean()
  def is_t_path({:t_path, _}), do: true
  def is_t_path(_), do: false

  @doc "Returns true if value is t_function variant"
  @spec is_t_function(t()) :: boolean()
  def is_t_function({:t_function, _}), do: true
  def is_t_function(_), do: false

  @doc "Returns true if value is t_anonymous variant"
  @spec is_t_anonymous(t()) :: boolean()
  def is_t_anonymous({:t_anonymous, _}), do: true
  def is_t_anonymous(_), do: false

  @doc "Returns true if value is t_parent variant"
  @spec is_t_parent(t()) :: boolean()
  def is_t_parent({:t_parent, _}), do: true
  def is_t_parent(_), do: false

  @doc "Returns true if value is t_extend variant"
  @spec is_t_extend(t()) :: boolean()
  def is_t_extend({:t_extend, _}), do: true
  def is_t_extend(_), do: false

  @doc "Returns true if value is t_optional variant"
  @spec is_t_optional(t()) :: boolean()
  def is_t_optional({:t_optional, _}), do: true
  def is_t_optional(_), do: false

  @doc "Returns true if value is t_named variant"
  @spec is_t_named(t()) :: boolean()
  def is_t_named({:t_named, _}), do: true
  def is_t_named(_), do: false

  @doc "Returns true if value is t_intersection variant"
  @spec is_t_intersection(t()) :: boolean()
  def is_t_intersection({:t_intersection, _}), do: true
  def is_t_intersection(_), do: false

  @doc "Extracts value from t_path variant, returns {:ok, value} or :error"
  @spec get_t_path_value(t()) :: {:ok, term()} | :error
  def get_t_path_value({:t_path, value}), do: {:ok, value}
  def get_t_path_value(_), do: :error

  @doc "Extracts value from t_function variant, returns {:ok, value} or :error"
  @spec get_t_function_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_function_value({:t_function, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_function_value(_), do: :error

  @doc "Extracts value from t_anonymous variant, returns {:ok, value} or :error"
  @spec get_t_anonymous_value(t()) :: {:ok, term()} | :error
  def get_t_anonymous_value({:t_anonymous, value}), do: {:ok, value}
  def get_t_anonymous_value(_), do: :error

  @doc "Extracts value from t_parent variant, returns {:ok, value} or :error"
  @spec get_t_parent_value(t()) :: {:ok, term()} | :error
  def get_t_parent_value({:t_parent, value}), do: {:ok, value}
  def get_t_parent_value(_), do: :error

  @doc "Extracts value from t_extend variant, returns {:ok, value} or :error"
  @spec get_t_extend_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_extend_value({:t_extend, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_extend_value(_), do: :error

  @doc "Extracts value from t_optional variant, returns {:ok, value} or :error"
  @spec get_t_optional_value(t()) :: {:ok, term()} | :error
  def get_t_optional_value({:t_optional, value}), do: {:ok, value}
  def get_t_optional_value(_), do: :error

  @doc "Extracts value from t_named variant, returns {:ok, value} or :error"
  @spec get_t_named_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_named_value({:t_named, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_named_value(_), do: :error

  @doc "Extracts value from t_intersection variant, returns {:ok, value} or :error"
  @spec get_t_intersection_value(t()) :: {:ok, term()} | :error
  def get_t_intersection_value({:t_intersection, value}), do: {:ok, value}
  def get_t_intersection_value(_), do: :error

end


defmodule TypeParam do
  @moduledoc """
  TypeParam enum generated from Haxe
  
  
	Represents a concrete type parameter in the AST.

	Haxe allows expressions in concrete type parameters, e.g.
	`new YourType<["hello", "world"]>`. In that case the value is `TPExpr` while
	in the normal case it's `TPType`.

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:t_p_type, term()} |
    {:t_p_expr, term()}

  @doc """
  Creates t_p_type enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_p_type(term()) :: {:t_p_type, term()}
  def t_p_type(arg0) do
    {:t_p_type, arg0}
  end

  @doc """
  Creates t_p_expr enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_p_expr(term()) :: {:t_p_expr, term()}
  def t_p_expr(arg0) do
    {:t_p_expr, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_p_type variant"
  @spec is_t_p_type(t()) :: boolean()
  def is_t_p_type({:t_p_type, _}), do: true
  def is_t_p_type(_), do: false

  @doc "Returns true if value is t_p_expr variant"
  @spec is_t_p_expr(t()) :: boolean()
  def is_t_p_expr({:t_p_expr, _}), do: true
  def is_t_p_expr(_), do: false

  @doc "Extracts value from t_p_type variant, returns {:ok, value} or :error"
  @spec get_t_p_type_value(t()) :: {:ok, term()} | :error
  def get_t_p_type_value({:t_p_type, value}), do: {:ok, value}
  def get_t_p_type_value(_), do: :error

  @doc "Extracts value from t_p_expr variant, returns {:ok, value} or :error"
  @spec get_t_p_expr_value(t()) :: {:ok, term()} | :error
  def get_t_p_expr_value({:t_p_expr, value}), do: {:ok, value}
  def get_t_p_expr_value(_), do: :error

end


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


defmodule FieldType do
  @moduledoc """
  FieldType enum generated from Haxe
  
  
	Represents the field type in the AST.

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:f_var, term(), term()} |
    {:f_fun, term()} |
    {:f_prop, term(), term(), term(), term()}

  @doc """
  Creates f_var enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_var(term(), term()) :: {:f_var, term(), term()}
  def f_var(arg0, arg1) do
    {:f_var, arg0, arg1}
  end

  @doc """
  Creates f_fun enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec f_fun(term()) :: {:f_fun, term()}
  def f_fun(arg0) do
    {:f_fun, arg0}
  end

  @doc """
  Creates f_prop enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
    - `arg3`: term()
  """
  @spec f_prop(term(), term(), term(), term()) :: {:f_prop, term(), term(), term(), term()}
  def f_prop(arg0, arg1, arg2, arg3) do
    {:f_prop, arg0, arg1, arg2, arg3}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is f_var variant"
  @spec is_f_var(t()) :: boolean()
  def is_f_var({:f_var, _}), do: true
  def is_f_var(_), do: false

  @doc "Returns true if value is f_fun variant"
  @spec is_f_fun(t()) :: boolean()
  def is_f_fun({:f_fun, _}), do: true
  def is_f_fun(_), do: false

  @doc "Returns true if value is f_prop variant"
  @spec is_f_prop(t()) :: boolean()
  def is_f_prop({:f_prop, _}), do: true
  def is_f_prop(_), do: false

  @doc "Extracts value from f_var variant, returns {:ok, value} or :error"
  @spec get_f_var_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_var_value({:f_var, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_var_value(_), do: :error

  @doc "Extracts value from f_fun variant, returns {:ok, value} or :error"
  @spec get_f_fun_value(t()) :: {:ok, term()} | :error
  def get_f_fun_value({:f_fun, value}), do: {:ok, value}
  def get_f_fun_value(_), do: :error

  @doc "Extracts value from f_prop variant, returns {:ok, value} or :error"
  @spec get_f_prop_value(t()) :: {:ok, {term(), term(), term(), term()}} | :error
  def get_f_prop_value({:f_prop, arg0, arg1, arg2, arg3}), do: {:ok, {arg0, arg1, arg2, arg3}}
  def get_f_prop_value(_), do: :error

end


defmodule TypeDefKind do
  @moduledoc """
  TypeDefKind enum generated from Haxe
  
  
	Represents a type definition kind.

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :t_d_enum |
    :t_d_structure |
    {:t_d_class, term(), term(), term(), term(), term()} |
    {:t_d_alias, term()} |
    {:t_d_abstract, term(), term(), term(), term()} |
    {:t_d_field, term(), term()}

  @doc "Creates t_d_enum enum value"
  @spec t_d_enum() :: :t_d_enum
  def t_d_enum(), do: :t_d_enum

  @doc "Creates t_d_structure enum value"
  @spec t_d_structure() :: :t_d_structure
  def t_d_structure(), do: :t_d_structure

  @doc """
  Creates t_d_class enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
    - `arg3`: term()
    - `arg4`: term()
  """
  @spec t_d_class(term(), term(), term(), term(), term()) :: {:t_d_class, term(), term(), term(), term(), term()}
  def t_d_class(arg0, arg1, arg2, arg3, arg4) do
    {:t_d_class, arg0, arg1, arg2, arg3, arg4}
  end

  @doc """
  Creates t_d_alias enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_d_alias(term()) :: {:t_d_alias, term()}
  def t_d_alias(arg0) do
    {:t_d_alias, arg0}
  end

  @doc """
  Creates t_d_abstract enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
    - `arg3`: term()
  """
  @spec t_d_abstract(term(), term(), term(), term()) :: {:t_d_abstract, term(), term(), term(), term()}
  def t_d_abstract(arg0, arg1, arg2, arg3) do
    {:t_d_abstract, arg0, arg1, arg2, arg3}
  end

  @doc """
  Creates t_d_field enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_d_field(term(), term()) :: {:t_d_field, term(), term()}
  def t_d_field(arg0, arg1) do
    {:t_d_field, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_d_enum variant"
  @spec is_t_d_enum(t()) :: boolean()
  def is_t_d_enum(:t_d_enum), do: true
  def is_t_d_enum(_), do: false

  @doc "Returns true if value is t_d_structure variant"
  @spec is_t_d_structure(t()) :: boolean()
  def is_t_d_structure(:t_d_structure), do: true
  def is_t_d_structure(_), do: false

  @doc "Returns true if value is t_d_class variant"
  @spec is_t_d_class(t()) :: boolean()
  def is_t_d_class({:t_d_class, _}), do: true
  def is_t_d_class(_), do: false

  @doc "Returns true if value is t_d_alias variant"
  @spec is_t_d_alias(t()) :: boolean()
  def is_t_d_alias({:t_d_alias, _}), do: true
  def is_t_d_alias(_), do: false

  @doc "Returns true if value is t_d_abstract variant"
  @spec is_t_d_abstract(t()) :: boolean()
  def is_t_d_abstract({:t_d_abstract, _}), do: true
  def is_t_d_abstract(_), do: false

  @doc "Returns true if value is t_d_field variant"
  @spec is_t_d_field(t()) :: boolean()
  def is_t_d_field({:t_d_field, _}), do: true
  def is_t_d_field(_), do: false

  @doc "Extracts value from t_d_class variant, returns {:ok, value} or :error"
  @spec get_t_d_class_value(t()) :: {:ok, {term(), term(), term(), term(), term()}} | :error
  def get_t_d_class_value({:t_d_class, arg0, arg1, arg2, arg3, arg4}), do: {:ok, {arg0, arg1, arg2, arg3, arg4}}
  def get_t_d_class_value(_), do: :error

  @doc "Extracts value from t_d_alias variant, returns {:ok, value} or :error"
  @spec get_t_d_alias_value(t()) :: {:ok, term()} | :error
  def get_t_d_alias_value({:t_d_alias, value}), do: {:ok, value}
  def get_t_d_alias_value(_), do: :error

  @doc "Extracts value from t_d_abstract variant, returns {:ok, value} or :error"
  @spec get_t_d_abstract_value(t()) :: {:ok, {term(), term(), term(), term()}} | :error
  def get_t_d_abstract_value({:t_d_abstract, arg0, arg1, arg2, arg3}), do: {:ok, {arg0, arg1, arg2, arg3}}
  def get_t_d_abstract_value(_), do: :error

  @doc "Extracts value from t_d_field variant, returns {:ok, value} or :error"
  @spec get_t_d_field_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_d_field_value({:t_d_field, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_d_field_value(_), do: :error

end


defmodule AbstractFlag do
  @moduledoc """
  AbstractFlag enum generated from Haxe
  
  
	Represents an abstract flag.

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :ab_enum |
    {:ab_from, term()} |
    {:ab_to, term()}

  @doc "Creates ab_enum enum value"
  @spec ab_enum() :: :ab_enum
  def ab_enum(), do: :ab_enum

  @doc """
  Creates ab_from enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec ab_from(term()) :: {:ab_from, term()}
  def ab_from(arg0) do
    {:ab_from, arg0}
  end

  @doc """
  Creates ab_to enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec ab_to(term()) :: {:ab_to, term()}
  def ab_to(arg0) do
    {:ab_to, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is ab_enum variant"
  @spec is_ab_enum(t()) :: boolean()
  def is_ab_enum(:ab_enum), do: true
  def is_ab_enum(_), do: false

  @doc "Returns true if value is ab_from variant"
  @spec is_ab_from(t()) :: boolean()
  def is_ab_from({:ab_from, _}), do: true
  def is_ab_from(_), do: false

  @doc "Returns true if value is ab_to variant"
  @spec is_ab_to(t()) :: boolean()
  def is_ab_to({:ab_to, _}), do: true
  def is_ab_to(_), do: false

  @doc "Extracts value from ab_from variant, returns {:ok, value} or :error"
  @spec get_ab_from_value(t()) :: {:ok, term()} | :error
  def get_ab_from_value({:ab_from, value}), do: {:ok, value}
  def get_ab_from_value(_), do: :error

  @doc "Extracts value from ab_to variant, returns {:ok, value} or :error"
  @spec get_ab_to_value(t()) :: {:ok, term()} | :error
  def get_ab_to_value({:ab_to, value}), do: {:ok, value}
  def get_ab_to_value(_), do: :error

end


defmodule ImportMode do
  @moduledoc """
  ImportMode enum generated from Haxe
  
  
	Represents the import mode.
	@see https://haxe.org/manual/type-system-import.html

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :i_normal |
    {:i_as_name, term()} |
    :i_all

  @doc "Creates i_normal enum value"
  @spec i_normal() :: :i_normal
  def i_normal(), do: :i_normal

  @doc """
  Creates i_as_name enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec i_as_name(term()) :: {:i_as_name, term()}
  def i_as_name(arg0) do
    {:i_as_name, arg0}
  end

  @doc "Creates i_all enum value"
  @spec i_all() :: :i_all
  def i_all(), do: :i_all

  # Predicate functions for pattern matching
  @doc "Returns true if value is i_normal variant"
  @spec is_i_normal(t()) :: boolean()
  def is_i_normal(:i_normal), do: true
  def is_i_normal(_), do: false

  @doc "Returns true if value is i_as_name variant"
  @spec is_i_as_name(t()) :: boolean()
  def is_i_as_name({:i_as_name, _}), do: true
  def is_i_as_name(_), do: false

  @doc "Returns true if value is i_all variant"
  @spec is_i_all(t()) :: boolean()
  def is_i_all(:i_all), do: true
  def is_i_all(_), do: false

  @doc "Extracts value from i_as_name variant, returns {:ok, value} or :error"
  @spec get_i_as_name_value(t()) :: {:ok, term()} | :error
  def get_i_as_name_value({:i_as_name, value}), do: {:ok, value}
  def get_i_as_name_value(_), do: :error

end
