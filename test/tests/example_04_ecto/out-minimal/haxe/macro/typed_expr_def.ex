defmodule TypedExprDef do
  @moduledoc """
  TypedExprDef enum generated from Haxe
  
  
  	Represents kind of a node in the typed AST.
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:t_const, term()} |
    {:t_local, term()} |
    {:t_array, term(), term()} |
    {:t_binop, term(), term(), term()} |
    {:t_field, term(), term()} |
    {:t_type_expr, term()} |
    {:t_parenthesis, term()} |
    {:t_object_decl, term()} |
    {:t_array_decl, term()} |
    {:t_call, term(), term()} |
    {:t_new, term(), term(), term()} |
    {:t_unop, term(), term(), term()} |
    {:t_function, term()} |
    {:t_var, term(), term()} |
    {:t_block, term()} |
    {:t_for, term(), term(), term()} |
    {:t_if, term(), term(), term()} |
    {:t_while, term(), term(), term()} |
    {:t_switch, term(), term(), term()} |
    {:t_try, term(), term()} |
    {:t_return, term()} |
    :t_break |
    :t_continue |
    {:t_throw, term()} |
    {:t_cast, term(), term()} |
    {:t_meta, term(), term()} |
    {:t_enum_parameter, term(), term(), term()} |
    {:t_enum_index, term()} |
    {:t_ident, term()}

  @doc """
  Creates t_const enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_const(term()) :: {:t_const, term()}
  def t_const(arg0) do
    {:t_const, arg0}
  end

  @doc """
  Creates t_local enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_local(term()) :: {:t_local, term()}
  def t_local(arg0) do
    {:t_local, arg0}
  end

  @doc """
  Creates t_array enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_array(term(), term()) :: {:t_array, term(), term()}
  def t_array(arg0, arg1) do
    {:t_array, arg0, arg1}
  end

  @doc """
  Creates t_binop enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_binop(term(), term(), term()) :: {:t_binop, term(), term(), term()}
  def t_binop(arg0, arg1, arg2) do
    {:t_binop, arg0, arg1, arg2}
  end

  @doc """
  Creates t_field enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_field(term(), term()) :: {:t_field, term(), term()}
  def t_field(arg0, arg1) do
    {:t_field, arg0, arg1}
  end

  @doc """
  Creates t_type_expr enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_type_expr(term()) :: {:t_type_expr, term()}
  def t_type_expr(arg0) do
    {:t_type_expr, arg0}
  end

  @doc """
  Creates t_parenthesis enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_parenthesis(term()) :: {:t_parenthesis, term()}
  def t_parenthesis(arg0) do
    {:t_parenthesis, arg0}
  end

  @doc """
  Creates t_object_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_object_decl(term()) :: {:t_object_decl, term()}
  def t_object_decl(arg0) do
    {:t_object_decl, arg0}
  end

  @doc """
  Creates t_array_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_array_decl(term()) :: {:t_array_decl, term()}
  def t_array_decl(arg0) do
    {:t_array_decl, arg0}
  end

  @doc """
  Creates t_call enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_call(term(), term()) :: {:t_call, term(), term()}
  def t_call(arg0, arg1) do
    {:t_call, arg0, arg1}
  end

  @doc """
  Creates t_new enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_new(term(), term(), term()) :: {:t_new, term(), term(), term()}
  def t_new(arg0, arg1, arg2) do
    {:t_new, arg0, arg1, arg2}
  end

  @doc """
  Creates t_unop enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_unop(term(), term(), term()) :: {:t_unop, term(), term(), term()}
  def t_unop(arg0, arg1, arg2) do
    {:t_unop, arg0, arg1, arg2}
  end

  @doc """
  Creates t_function enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_function(term()) :: {:t_function, term()}
  def t_function(arg0) do
    {:t_function, arg0}
  end

  @doc """
  Creates t_var enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_var(term(), term()) :: {:t_var, term(), term()}
  def t_var(arg0, arg1) do
    {:t_var, arg0, arg1}
  end

  @doc """
  Creates t_block enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_block(term()) :: {:t_block, term()}
  def t_block(arg0) do
    {:t_block, arg0}
  end

  @doc """
  Creates t_for enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_for(term(), term(), term()) :: {:t_for, term(), term(), term()}
  def t_for(arg0, arg1, arg2) do
    {:t_for, arg0, arg1, arg2}
  end

  @doc """
  Creates t_if enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_if(term(), term(), term()) :: {:t_if, term(), term(), term()}
  def t_if(arg0, arg1, arg2) do
    {:t_if, arg0, arg1, arg2}
  end

  @doc """
  Creates t_while enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_while(term(), term(), term()) :: {:t_while, term(), term(), term()}
  def t_while(arg0, arg1, arg2) do
    {:t_while, arg0, arg1, arg2}
  end

  @doc """
  Creates t_switch enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_switch(term(), term(), term()) :: {:t_switch, term(), term(), term()}
  def t_switch(arg0, arg1, arg2) do
    {:t_switch, arg0, arg1, arg2}
  end

  @doc """
  Creates t_try enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_try(term(), term()) :: {:t_try, term(), term()}
  def t_try(arg0, arg1) do
    {:t_try, arg0, arg1}
  end

  @doc """
  Creates t_return enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_return(term()) :: {:t_return, term()}
  def t_return(arg0) do
    {:t_return, arg0}
  end

  @doc "Creates t_break enum value"
  @spec t_break() :: :t_break
  def t_break(), do: :t_break

  @doc "Creates t_continue enum value"
  @spec t_continue() :: :t_continue
  def t_continue(), do: :t_continue

  @doc """
  Creates t_throw enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_throw(term()) :: {:t_throw, term()}
  def t_throw(arg0) do
    {:t_throw, arg0}
  end

  @doc """
  Creates t_cast enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_cast(term(), term()) :: {:t_cast, term(), term()}
  def t_cast(arg0, arg1) do
    {:t_cast, arg0, arg1}
  end

  @doc """
  Creates t_meta enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_meta(term(), term()) :: {:t_meta, term(), term()}
  def t_meta(arg0, arg1) do
    {:t_meta, arg0, arg1}
  end

  @doc """
  Creates t_enum_parameter enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_enum_parameter(term(), term(), term()) :: {:t_enum_parameter, term(), term(), term()}
  def t_enum_parameter(arg0, arg1, arg2) do
    {:t_enum_parameter, arg0, arg1, arg2}
  end

  @doc """
  Creates t_enum_index enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_enum_index(term()) :: {:t_enum_index, term()}
  def t_enum_index(arg0) do
    {:t_enum_index, arg0}
  end

  @doc """
  Creates t_ident enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_ident(term()) :: {:t_ident, term()}
  def t_ident(arg0) do
    {:t_ident, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_const variant"
  @spec is_t_const(t()) :: boolean()
  def is_t_const({:t_const, _}), do: true
  def is_t_const(_), do: false

  @doc "Returns true if value is t_local variant"
  @spec is_t_local(t()) :: boolean()
  def is_t_local({:t_local, _}), do: true
  def is_t_local(_), do: false

  @doc "Returns true if value is t_array variant"
  @spec is_t_array(t()) :: boolean()
  def is_t_array({:t_array, _}), do: true
  def is_t_array(_), do: false

  @doc "Returns true if value is t_binop variant"
  @spec is_t_binop(t()) :: boolean()
  def is_t_binop({:t_binop, _}), do: true
  def is_t_binop(_), do: false

  @doc "Returns true if value is t_field variant"
  @spec is_t_field(t()) :: boolean()
  def is_t_field({:t_field, _}), do: true
  def is_t_field(_), do: false

  @doc "Returns true if value is t_type_expr variant"
  @spec is_t_type_expr(t()) :: boolean()
  def is_t_type_expr({:t_type_expr, _}), do: true
  def is_t_type_expr(_), do: false

  @doc "Returns true if value is t_parenthesis variant"
  @spec is_t_parenthesis(t()) :: boolean()
  def is_t_parenthesis({:t_parenthesis, _}), do: true
  def is_t_parenthesis(_), do: false

  @doc "Returns true if value is t_object_decl variant"
  @spec is_t_object_decl(t()) :: boolean()
  def is_t_object_decl({:t_object_decl, _}), do: true
  def is_t_object_decl(_), do: false

  @doc "Returns true if value is t_array_decl variant"
  @spec is_t_array_decl(t()) :: boolean()
  def is_t_array_decl({:t_array_decl, _}), do: true
  def is_t_array_decl(_), do: false

  @doc "Returns true if value is t_call variant"
  @spec is_t_call(t()) :: boolean()
  def is_t_call({:t_call, _}), do: true
  def is_t_call(_), do: false

  @doc "Returns true if value is t_new variant"
  @spec is_t_new(t()) :: boolean()
  def is_t_new({:t_new, _}), do: true
  def is_t_new(_), do: false

  @doc "Returns true if value is t_unop variant"
  @spec is_t_unop(t()) :: boolean()
  def is_t_unop({:t_unop, _}), do: true
  def is_t_unop(_), do: false

  @doc "Returns true if value is t_function variant"
  @spec is_t_function(t()) :: boolean()
  def is_t_function({:t_function, _}), do: true
  def is_t_function(_), do: false

  @doc "Returns true if value is t_var variant"
  @spec is_t_var(t()) :: boolean()
  def is_t_var({:t_var, _}), do: true
  def is_t_var(_), do: false

  @doc "Returns true if value is t_block variant"
  @spec is_t_block(t()) :: boolean()
  def is_t_block({:t_block, _}), do: true
  def is_t_block(_), do: false

  @doc "Returns true if value is t_for variant"
  @spec is_t_for(t()) :: boolean()
  def is_t_for({:t_for, _}), do: true
  def is_t_for(_), do: false

  @doc "Returns true if value is t_if variant"
  @spec is_t_if(t()) :: boolean()
  def is_t_if({:t_if, _}), do: true
  def is_t_if(_), do: false

  @doc "Returns true if value is t_while variant"
  @spec is_t_while(t()) :: boolean()
  def is_t_while({:t_while, _}), do: true
  def is_t_while(_), do: false

  @doc "Returns true if value is t_switch variant"
  @spec is_t_switch(t()) :: boolean()
  def is_t_switch({:t_switch, _}), do: true
  def is_t_switch(_), do: false

  @doc "Returns true if value is t_try variant"
  @spec is_t_try(t()) :: boolean()
  def is_t_try({:t_try, _}), do: true
  def is_t_try(_), do: false

  @doc "Returns true if value is t_return variant"
  @spec is_t_return(t()) :: boolean()
  def is_t_return({:t_return, _}), do: true
  def is_t_return(_), do: false

  @doc "Returns true if value is t_break variant"
  @spec is_t_break(t()) :: boolean()
  def is_t_break(:t_break), do: true
  def is_t_break(_), do: false

  @doc "Returns true if value is t_continue variant"
  @spec is_t_continue(t()) :: boolean()
  def is_t_continue(:t_continue), do: true
  def is_t_continue(_), do: false

  @doc "Returns true if value is t_throw variant"
  @spec is_t_throw(t()) :: boolean()
  def is_t_throw({:t_throw, _}), do: true
  def is_t_throw(_), do: false

  @doc "Returns true if value is t_cast variant"
  @spec is_t_cast(t()) :: boolean()
  def is_t_cast({:t_cast, _}), do: true
  def is_t_cast(_), do: false

  @doc "Returns true if value is t_meta variant"
  @spec is_t_meta(t()) :: boolean()
  def is_t_meta({:t_meta, _}), do: true
  def is_t_meta(_), do: false

  @doc "Returns true if value is t_enum_parameter variant"
  @spec is_t_enum_parameter(t()) :: boolean()
  def is_t_enum_parameter({:t_enum_parameter, _}), do: true
  def is_t_enum_parameter(_), do: false

  @doc "Returns true if value is t_enum_index variant"
  @spec is_t_enum_index(t()) :: boolean()
  def is_t_enum_index({:t_enum_index, _}), do: true
  def is_t_enum_index(_), do: false

  @doc "Returns true if value is t_ident variant"
  @spec is_t_ident(t()) :: boolean()
  def is_t_ident({:t_ident, _}), do: true
  def is_t_ident(_), do: false

  @doc "Extracts value from t_const variant, returns {:ok, value} or :error"
  @spec get_t_const_value(t()) :: {:ok, term()} | :error
  def get_t_const_value({:t_const, value}), do: {:ok, value}
  def get_t_const_value(_), do: :error

  @doc "Extracts value from t_local variant, returns {:ok, value} or :error"
  @spec get_t_local_value(t()) :: {:ok, term()} | :error
  def get_t_local_value({:t_local, value}), do: {:ok, value}
  def get_t_local_value(_), do: :error

  @doc "Extracts value from t_array variant, returns {:ok, value} or :error"
  @spec get_t_array_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_array_value({:t_array, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_array_value(_), do: :error

  @doc "Extracts value from t_binop variant, returns {:ok, value} or :error"
  @spec get_t_binop_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_binop_value({:t_binop, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_binop_value(_), do: :error

  @doc "Extracts value from t_field variant, returns {:ok, value} or :error"
  @spec get_t_field_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_field_value({:t_field, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_field_value(_), do: :error

  @doc "Extracts value from t_type_expr variant, returns {:ok, value} or :error"
  @spec get_t_type_expr_value(t()) :: {:ok, term()} | :error
  def get_t_type_expr_value({:t_type_expr, value}), do: {:ok, value}
  def get_t_type_expr_value(_), do: :error

  @doc "Extracts value from t_parenthesis variant, returns {:ok, value} or :error"
  @spec get_t_parenthesis_value(t()) :: {:ok, term()} | :error
  def get_t_parenthesis_value({:t_parenthesis, value}), do: {:ok, value}
  def get_t_parenthesis_value(_), do: :error

  @doc "Extracts value from t_object_decl variant, returns {:ok, value} or :error"
  @spec get_t_object_decl_value(t()) :: {:ok, term()} | :error
  def get_t_object_decl_value({:t_object_decl, value}), do: {:ok, value}
  def get_t_object_decl_value(_), do: :error

  @doc "Extracts value from t_array_decl variant, returns {:ok, value} or :error"
  @spec get_t_array_decl_value(t()) :: {:ok, term()} | :error
  def get_t_array_decl_value({:t_array_decl, value}), do: {:ok, value}
  def get_t_array_decl_value(_), do: :error

  @doc "Extracts value from t_call variant, returns {:ok, value} or :error"
  @spec get_t_call_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_call_value({:t_call, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_call_value(_), do: :error

  @doc "Extracts value from t_new variant, returns {:ok, value} or :error"
  @spec get_t_new_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_new_value({:t_new, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_new_value(_), do: :error

  @doc "Extracts value from t_unop variant, returns {:ok, value} or :error"
  @spec get_t_unop_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_unop_value({:t_unop, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_unop_value(_), do: :error

  @doc "Extracts value from t_function variant, returns {:ok, value} or :error"
  @spec get_t_function_value(t()) :: {:ok, term()} | :error
  def get_t_function_value({:t_function, value}), do: {:ok, value}
  def get_t_function_value(_), do: :error

  @doc "Extracts value from t_var variant, returns {:ok, value} or :error"
  @spec get_t_var_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_var_value({:t_var, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_var_value(_), do: :error

  @doc "Extracts value from t_block variant, returns {:ok, value} or :error"
  @spec get_t_block_value(t()) :: {:ok, term()} | :error
  def get_t_block_value({:t_block, value}), do: {:ok, value}
  def get_t_block_value(_), do: :error

  @doc "Extracts value from t_for variant, returns {:ok, value} or :error"
  @spec get_t_for_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_for_value({:t_for, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_for_value(_), do: :error

  @doc "Extracts value from t_if variant, returns {:ok, value} or :error"
  @spec get_t_if_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_if_value({:t_if, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_if_value(_), do: :error

  @doc "Extracts value from t_while variant, returns {:ok, value} or :error"
  @spec get_t_while_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_while_value({:t_while, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_while_value(_), do: :error

  @doc "Extracts value from t_switch variant, returns {:ok, value} or :error"
  @spec get_t_switch_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_switch_value({:t_switch, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_switch_value(_), do: :error

  @doc "Extracts value from t_try variant, returns {:ok, value} or :error"
  @spec get_t_try_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_try_value({:t_try, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_try_value(_), do: :error

  @doc "Extracts value from t_return variant, returns {:ok, value} or :error"
  @spec get_t_return_value(t()) :: {:ok, term()} | :error
  def get_t_return_value({:t_return, value}), do: {:ok, value}
  def get_t_return_value(_), do: :error

  @doc "Extracts value from t_throw variant, returns {:ok, value} or :error"
  @spec get_t_throw_value(t()) :: {:ok, term()} | :error
  def get_t_throw_value({:t_throw, value}), do: {:ok, value}
  def get_t_throw_value(_), do: :error

  @doc "Extracts value from t_cast variant, returns {:ok, value} or :error"
  @spec get_t_cast_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_cast_value({:t_cast, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_cast_value(_), do: :error

  @doc "Extracts value from t_meta variant, returns {:ok, value} or :error"
  @spec get_t_meta_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_meta_value({:t_meta, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_meta_value(_), do: :error

  @doc "Extracts value from t_enum_parameter variant, returns {:ok, value} or :error"
  @spec get_t_enum_parameter_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_enum_parameter_value({:t_enum_parameter, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_enum_parameter_value(_), do: :error

  @doc "Extracts value from t_enum_index variant, returns {:ok, value} or :error"
  @spec get_t_enum_index_value(t()) :: {:ok, term()} | :error
  def get_t_enum_index_value({:t_enum_index, value}), do: {:ok, value}
  def get_t_enum_index_value(_), do: :error

  @doc "Extracts value from t_ident variant, returns {:ok, value} or :error"
  @spec get_t_ident_value(t()) :: {:ok, term()} | :error
  def get_t_ident_value({:t_ident, value}), do: {:ok, value}
  def get_t_ident_value(_), do: :error

end
