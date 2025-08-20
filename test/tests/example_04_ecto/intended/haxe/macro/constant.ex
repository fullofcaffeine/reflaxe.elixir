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
