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
