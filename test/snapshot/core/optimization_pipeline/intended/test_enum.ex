defmodule TestEnum do
  @moduledoc """
  TestEnum enum generated from Haxe
  
  
   * Test case to explore differences between onAfterTyping and onGenerate
   * This demonstrates what optimizations Haxe performs between these phases
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:option1, term()} |
    {:option2, term()} |
    :option3

  @doc """
  Creates option1 enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec option1(term()) :: {:option1, term()}
  def option1(arg0) do
    {:option1, arg0}
  end

  @doc """
  Creates option2 enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec option2(term()) :: {:option2, term()}
  def option2(arg0) do
    {:option2, arg0}
  end

  @doc "Creates option3 enum value"
  @spec option3() :: :option3
  def option3(), do: :option3

  # Predicate functions for pattern matching
  @doc "Returns true if value is option1 variant"
  @spec is_option1(t()) :: boolean()
  def is_option1({:option1, _}), do: true
  def is_option1(_), do: false

  @doc "Returns true if value is option2 variant"
  @spec is_option2(t()) :: boolean()
  def is_option2({:option2, _}), do: true
  def is_option2(_), do: false

  @doc "Returns true if value is option3 variant"
  @spec is_option3(t()) :: boolean()
  def is_option3(:option3), do: true
  def is_option3(_), do: false

  @doc "Extracts value from option1 variant, returns {:ok, value} or :error"
  @spec get_option1_value(t()) :: {:ok, term()} | :error
  def get_option1_value({:option1, value}), do: {:ok, value}
  def get_option1_value(_), do: :error

  @doc "Extracts value from option2 variant, returns {:ok, value} or :error"
  @spec get_option2_value(t()) :: {:ok, term()} | :error
  def get_option2_value({:option2, value}), do: {:ok, value}
  def get_option2_value(_), do: :error

end
