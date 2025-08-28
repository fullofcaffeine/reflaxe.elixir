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
