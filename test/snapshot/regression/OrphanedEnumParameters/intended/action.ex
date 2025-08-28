defmodule Action do
  @moduledoc """
  Action enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:move, term(), term(), term()} |
    {:rotate, term(), term()} |
    {:scale, term()}

  @doc """
  Creates move enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec move(term(), term(), term()) :: {:move, term(), term(), term()}
  def move(arg0, arg1, arg2) do
    {:move, arg0, arg1, arg2}
  end

  @doc """
  Creates rotate enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec rotate(term(), term()) :: {:rotate, term(), term()}
  def rotate(arg0, arg1) do
    {:rotate, arg0, arg1}
  end

  @doc """
  Creates scale enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec scale(term()) :: {:scale, term()}
  def scale(arg0) do
    {:scale, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is move variant"
  @spec is_move(t()) :: boolean()
  def is_move({:move, _}), do: true
  def is_move(_), do: false

  @doc "Returns true if value is rotate variant"
  @spec is_rotate(t()) :: boolean()
  def is_rotate({:rotate, _}), do: true
  def is_rotate(_), do: false

  @doc "Returns true if value is scale variant"
  @spec is_scale(t()) :: boolean()
  def is_scale({:scale, _}), do: true
  def is_scale(_), do: false

  @doc "Extracts value from move variant, returns {:ok, value} or :error"
  @spec get_move_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_move_value({:move, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_move_value(_), do: :error

  @doc "Extracts value from rotate variant, returns {:ok, value} or :error"
  @spec get_rotate_value(t()) :: {:ok, {term(), term()}} | :error
  def get_rotate_value({:rotate, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_rotate_value(_), do: :error

  @doc "Extracts value from scale variant, returns {:ok, value} or :error"
  @spec get_scale_value(t()) :: {:ok, term()} | :error
  def get_scale_value({:scale, value}), do: {:ok, value}
  def get_scale_value(_), do: :error

end
