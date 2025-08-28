defmodule ElixirAtom do
  @moduledoc """
  ElixirAtom enum generated from Haxe
  
  
   * Elixir atom-like constants for GenServer return tuples
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :o_k |
    :s_t_o_p |
    :r_e_p_l_y |
    :n_o_r_e_p_l_y |
    :c_o_n_t_i_n_u_e |
    :h_i_b_e_r_n_a_t_e

  @doc "Creates o_k enum value"
  @spec o_k() :: :o_k
  def o_k(), do: :o_k

  @doc "Creates s_t_o_p enum value"
  @spec s_t_o_p() :: :s_t_o_p
  def s_t_o_p(), do: :s_t_o_p

  @doc "Creates r_e_p_l_y enum value"
  @spec r_e_p_l_y() :: :r_e_p_l_y
  def r_e_p_l_y(), do: :r_e_p_l_y

  @doc "Creates n_o_r_e_p_l_y enum value"
  @spec n_o_r_e_p_l_y() :: :n_o_r_e_p_l_y
  def n_o_r_e_p_l_y(), do: :n_o_r_e_p_l_y

  @doc "Creates c_o_n_t_i_n_u_e enum value"
  @spec c_o_n_t_i_n_u_e() :: :c_o_n_t_i_n_u_e
  def c_o_n_t_i_n_u_e(), do: :c_o_n_t_i_n_u_e

  @doc "Creates h_i_b_e_r_n_a_t_e enum value"
  @spec h_i_b_e_r_n_a_t_e() :: :h_i_b_e_r_n_a_t_e
  def h_i_b_e_r_n_a_t_e(), do: :h_i_b_e_r_n_a_t_e

  # Predicate functions for pattern matching
  @doc "Returns true if value is o_k variant"
  @spec is_o_k(t()) :: boolean()
  def is_o_k(:o_k), do: true
  def is_o_k(_), do: false

  @doc "Returns true if value is s_t_o_p variant"
  @spec is_s_t_o_p(t()) :: boolean()
  def is_s_t_o_p(:s_t_o_p), do: true
  def is_s_t_o_p(_), do: false

  @doc "Returns true if value is r_e_p_l_y variant"
  @spec is_r_e_p_l_y(t()) :: boolean()
  def is_r_e_p_l_y(:r_e_p_l_y), do: true
  def is_r_e_p_l_y(_), do: false

  @doc "Returns true if value is n_o_r_e_p_l_y variant"
  @spec is_n_o_r_e_p_l_y(t()) :: boolean()
  def is_n_o_r_e_p_l_y(:n_o_r_e_p_l_y), do: true
  def is_n_o_r_e_p_l_y(_), do: false

  @doc "Returns true if value is c_o_n_t_i_n_u_e variant"
  @spec is_c_o_n_t_i_n_u_e(t()) :: boolean()
  def is_c_o_n_t_i_n_u_e(:c_o_n_t_i_n_u_e), do: true
  def is_c_o_n_t_i_n_u_e(_), do: false

  @doc "Returns true if value is h_i_b_e_r_n_a_t_e variant"
  @spec is_h_i_b_e_r_n_a_t_e(t()) :: boolean()
  def is_h_i_b_e_r_n_a_t_e(:h_i_b_e_r_n_a_t_e), do: true
  def is_h_i_b_e_r_n_a_t_e(_), do: false

end
