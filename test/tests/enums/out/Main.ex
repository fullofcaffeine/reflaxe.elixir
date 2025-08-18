defmodule Color do
  @moduledoc """
  Color enum generated from Haxe
  
  
 * Enum test case
 * Tests enum compilation and pattern matching
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :red |
    :green |
    :blue |
    {:r_g_b, term(), term(), term()}

  @doc "Creates red enum value"
  @spec red() :: :red
  def red(), do: :red

  @doc "Creates green enum value"
  @spec green() :: :green
  def green(), do: :green

  @doc "Creates blue enum value"
  @spec blue() :: :blue
  def blue(), do: :blue

  @doc """
  Creates r_g_b enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec r_g_b(term(), term(), term()) :: {:r_g_b, term(), term(), term()}
  def r_g_b(arg0, arg1, arg2) do
    {:r_g_b, arg0, arg1, arg2}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is red variant"
  @spec is_red(t()) :: boolean()
  def is_red(:red), do: true
  def is_red(_), do: false

  @doc "Returns true if value is green variant"
  @spec is_green(t()) :: boolean()
  def is_green(:green), do: true
  def is_green(_), do: false

  @doc "Returns true if value is blue variant"
  @spec is_blue(t()) :: boolean()
  def is_blue(:blue), do: true
  def is_blue(_), do: false

  @doc "Returns true if value is r_g_b variant"
  @spec is_r_g_b(t()) :: boolean()
  def is_r_g_b({:r_g_b, _}), do: true
  def is_r_g_b(_), do: false

  @doc "Extracts value from r_g_b variant, returns {:ok, value} or :error"
  @spec get_r_g_b_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_r_g_b_value({:r_g_b, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_r_g_b_value(_), do: :error

end


defmodule Option do
  @moduledoc """
  Option enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:some, term()} |
    :none

  @doc """
  Creates some enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec some(term()) :: {:some, term()}
  def some(arg0) do
    {:some, arg0}
  end

  @doc "Creates none enum value"
  @spec none() :: :none
  def none(), do: :none

  # Predicate functions for pattern matching
  @doc "Returns true if value is some variant"
  @spec is_some(t()) :: boolean()
  def is_some({:some, _}), do: true
  def is_some(_), do: false

  @doc "Returns true if value is none variant"
  @spec is_none(t()) :: boolean()
  def is_none(:none), do: true
  def is_none(_), do: false

  @doc "Extracts value from some variant, returns {:ok, value} or :error"
  @spec get_some_value(t()) :: {:ok, term()} | :error
  def get_some_value({:some, value}), do: {:ok, value}
  def get_some_value(_), do: :error

end


defmodule Tree do
  @moduledoc """
  Tree enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:leaf, term()} |
    {:node_, term(), term()}

  @doc """
  Creates leaf enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec leaf(term()) :: {:leaf, term()}
  def leaf(arg0) do
    {:leaf, arg0}
  end

  @doc """
  Creates node_ enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec node_(term(), term()) :: {:node_, term(), term()}
  def node_(arg0, arg1) do
    {:node_, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is leaf variant"
  @spec is_leaf(t()) :: boolean()
  def is_leaf({:leaf, _}), do: true
  def is_leaf(_), do: false

  @doc "Returns true if value is node_ variant"
  @spec is_node_(t()) :: boolean()
  def is_node_({:node_, _}), do: true
  def is_node_(_), do: false

  @doc "Extracts value from leaf variant, returns {:ok, value} or :error"
  @spec get_leaf_value(t()) :: {:ok, term()} | :error
  def get_leaf_value({:leaf, value}), do: {:ok, value}
  def get_leaf_value(_), do: :error

  @doc "Extracts value from node_ variant, returns {:ok, value} or :error"
  @spec get_node__value(t()) :: {:ok, {term(), term()}} | :error
  def get_node__value({:node_, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_node__value(_), do: :error

end
