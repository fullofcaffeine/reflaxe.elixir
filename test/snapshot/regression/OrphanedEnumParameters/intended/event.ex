defmodule Event do
  @moduledoc """
  Event enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:click, term(), term()} |
    {:hover, term(), term()} |
    {:key_press, term()}

  @doc """
  Creates click enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec click(term(), term()) :: {:click, term(), term()}
  def click(arg0, arg1) do
    {:click, arg0, arg1}
  end

  @doc """
  Creates hover enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec hover(term(), term()) :: {:hover, term(), term()}
  def hover(arg0, arg1) do
    {:hover, arg0, arg1}
  end

  @doc """
  Creates key_press enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec key_press(term()) :: {:key_press, term()}
  def key_press(arg0) do
    {:key_press, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is click variant"
  @spec is_click(t()) :: boolean()
  def is_click({:click, _}), do: true
  def is_click(_), do: false

  @doc "Returns true if value is hover variant"
  @spec is_hover(t()) :: boolean()
  def is_hover({:hover, _}), do: true
  def is_hover(_), do: false

  @doc "Returns true if value is key_press variant"
  @spec is_key_press(t()) :: boolean()
  def is_key_press({:key_press, _}), do: true
  def is_key_press(_), do: false

  @doc "Extracts value from click variant, returns {:ok, value} or :error"
  @spec get_click_value(t()) :: {:ok, {term(), term()}} | :error
  def get_click_value({:click, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_click_value(_), do: :error

  @doc "Extracts value from hover variant, returns {:ok, value} or :error"
  @spec get_hover_value(t()) :: {:ok, {term(), term()}} | :error
  def get_hover_value({:hover, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_hover_value(_), do: :error

  @doc "Extracts value from key_press variant, returns {:ok, value} or :error"
  @spec get_key_press_value(t()) :: {:ok, term()} | :error
  def get_key_press_value({:key_press, value}), do: {:ok, value}
  def get_key_press_value(_), do: :error

end
