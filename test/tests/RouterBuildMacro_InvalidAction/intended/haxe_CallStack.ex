defmodule CallStack_Impl_ do
  use Bitwise
  @moduledoc """
  CallStack_Impl_ module generated from Haxe
  """

end


defmodule StackItem do
  @moduledoc """
  StackItem enum generated from Haxe
  
  
	Elements return by `CallStack` methods.

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:module, term()} |
    {:method, term(), term()} |
    {:local_function, term()} |
    {:file_pos, term(), term(), term(), term()} |
    :c_function

  @doc """
  Creates module enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec module(term()) :: {:module, term()}
  def module(arg0) do
    {:module, arg0}
  end

  @doc """
  Creates method enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec method(term(), term()) :: {:method, term(), term()}
  def method(arg0, arg1) do
    {:method, arg0, arg1}
  end

  @doc """
  Creates local_function enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec local_function(term()) :: {:local_function, term()}
  def local_function(arg0) do
    {:local_function, arg0}
  end

  @doc """
  Creates file_pos enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
    - `arg3`: term()
  """
  @spec file_pos(term(), term(), term(), term()) :: {:file_pos, term(), term(), term(), term()}
  def file_pos(arg0, arg1, arg2, arg3) do
    {:file_pos, arg0, arg1, arg2, arg3}
  end

  @doc "Creates c_function enum value"
  @spec c_function() :: :c_function
  def c_function(), do: :c_function

  # Predicate functions for pattern matching
  @doc "Returns true if value is module variant"
  @spec is_module(t()) :: boolean()
  def is_module({:module, _}), do: true
  def is_module(_), do: false

  @doc "Returns true if value is method variant"
  @spec is_method(t()) :: boolean()
  def is_method({:method, _}), do: true
  def is_method(_), do: false

  @doc "Returns true if value is local_function variant"
  @spec is_local_function(t()) :: boolean()
  def is_local_function({:local_function, _}), do: true
  def is_local_function(_), do: false

  @doc "Returns true if value is file_pos variant"
  @spec is_file_pos(t()) :: boolean()
  def is_file_pos({:file_pos, _}), do: true
  def is_file_pos(_), do: false

  @doc "Returns true if value is c_function variant"
  @spec is_c_function(t()) :: boolean()
  def is_c_function(:c_function), do: true
  def is_c_function(_), do: false

  @doc "Extracts value from module variant, returns {:ok, value} or :error"
  @spec get_module_value(t()) :: {:ok, term()} | :error
  def get_module_value({:module, value}), do: {:ok, value}
  def get_module_value(_), do: :error

  @doc "Extracts value from method variant, returns {:ok, value} or :error"
  @spec get_method_value(t()) :: {:ok, {term(), term()}} | :error
  def get_method_value({:method, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_method_value(_), do: :error

  @doc "Extracts value from local_function variant, returns {:ok, value} or :error"
  @spec get_local_function_value(t()) :: {:ok, term()} | :error
  def get_local_function_value({:local_function, value}), do: {:ok, value}
  def get_local_function_value(_), do: :error

  @doc "Extracts value from file_pos variant, returns {:ok, value} or :error"
  @spec get_file_pos_value(t()) :: {:ok, {term(), term(), term(), term()}} | :error
  def get_file_pos_value({:file_pos, arg0, arg1, arg2, arg3}), do: {:ok, {arg0, arg1, arg2, arg3}}
  def get_file_pos_value(_), do: :error

end
