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
