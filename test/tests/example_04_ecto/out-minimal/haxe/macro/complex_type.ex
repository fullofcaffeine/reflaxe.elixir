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
